package graphql.parser;

import graphql.ASTDefs;

import tink.parse.ParserBase;
import tink.parse.Char.*;

using tink.CoreApi;

@:structInit
class Pos {
  public var file:String;
  public var min:Int;
  public var max:Int;
}

@:structInit
class Err {
  public var message:String;
  public var pos:Pos;
}

class Parser extends tink.parse.ParserBase<Pos, Err>
{
  public var document(default,null):Document;
  private var _filename:String;

  public function new(schema:String, filename:String='Untitled')
  {
    super(schema);
    _filename = filename;
    try {
      document = readDocument();
    } catch (e:Err) {
      format_and_rethrow(_filename, this.source, e);
    }
  }

  static function format_and_rethrow(filename:String, source:tink.parse.StringSlice, e:Err)
  {
    var line_num = 1;
    var off = 0;
    for (i in 0...e.pos.min) if (source.fastGet(i)=="\n".code) {
      off = i;
      line_num++;
    }
    // Line number error message
    var msg = '$filename:$line_num: characters ${ e.pos.min-off }-${ e.pos.max-off } Error: ${ e.message }';
    throw msg;
  }

  static var COMMENT_CHAR = '#'.code;

  private function readDocument()
  {
    var defs = [];
    while (true) {
      skipWhitespace(true);

      if (done()) break;

      switch readDefinition() {
        case Success(d):
          defs.push(d);
        case Failure(f):
          throw makeError(f.message, makePos(pos));
      }
    }
    return { definitions:defs };
  }

  private function readDefinition():Outcome<BaseNode, Err>
  {
    skipWhitespace(true);
    var p = pos;
    var rtn:Outcome<BaseNode, Err> = switch ident(true) {
      case Success(v) if (v=="type"): readTypeDefinition(p);
      case Success(v) if (v=="interface"): readTypeDefinition(p, true);
      case Success(v) if (v=="schema"): readTypeDefinition(p, false, true);
      case Success(v) if (v=="enum"): readEnumDefinition(p);
      case Success(v) if (v=="union"): readUnionDefinition(p);
      case Success(_): Failure(makeError('Got "${ source[p...pos] }", expecting keyword: type interface enum schema union', makePos(p)));
      case Failure(e): Failure(e);
    }
    return rtn;
  }

  private function readTypeDefinition(start:Int,
                                      is_interface:Bool=false,
                                      is_schema:Bool=false):Outcome<BaseNode, Err> {
    var def = {
      loc: { start:start, end:start, source:_filename, startToken:null, endToken:null  },
      kind: Kind.OBJECT_TYPE_DEFINITION,
      name:null,
      fields:[]
    };
    if (is_interface) def.kind = Kind.INTERFACE_TYPE_DEFINITION;
    if (is_schema) def.kind = Kind.SCHEMA_DEFINITION;
    var interfaces = [];
    skipWhitespace(true);
    if (!is_schema) {
      var name:String = ident().sure();
      def.name = mkNameNode(name);
      skipWhitespace(true);
    }

    var err:Outcome<BaseNode, Err> = null;
    if (allow('implements')) {
      if (is_interface) return fail('Interfaces cannot implement interfaces.');
      parseRepeatedly(function() {
        var i = ident();
        if (!i.isSuccess()) { err = Failure(i.getParameters()[0]); return; }
        var if_type:NamedTypeNode = { kind:Kind.NAMED_TYPE, name:mkNameNode(i.sure()) };
        interfaces.push(if_type);
      }, {end:'{', sep:'&', allowTrailing:false});
    } else {
      expect('{');
    }
    if (err!=null) return err;

    while (true) {
      switch readFieldDefinition() {
        case Success(field): def.fields.push(field);
        case Failure(e): return Failure(e);
      }
      if (allow('}')) break;
    }
    def.loc.end = pos;

    skipWhitespace(true);

    if (is_interface) {
      var inode:InterfaceTypeDefinitionNode = def;
      return Success(inode);
    } else if (is_schema) {
      // TODO: var snode:SchemaDefinitionNode = def;
      throw 'SchemaDefinitionNode is not yet supported...';
    } else {
      var onode:ObjectTypeDefinitionNode = {
        name:def.name, loc:def.loc, kind:def.kind, fields:def.fields, interfaces:interfaces
      };
      return Success(onode);
    }
  }
  function mkNameNode(name:String) return { kind:Kind.NAMED_TYPE, value:name, loc:null };

  private function readEnumDefinition(start:Int):Outcome<BaseNode, Err>
  {
    var def:EnumTypeDefinitionNode = {
      loc: { start:start, end:pos, source:_filename, startToken:null, endToken:null },
      kind:Kind.ENUM_TYPE_DEFINITION,
      name:null,
      values:[]
    };
    skipWhitespace(true);
    var name:String = ident().sure();
    def.name = mkNameNode(name);
    skipWhitespace(true);

    expect('{');
    while (true) {
      skipWhitespace(true);
      var i = ident();
      if (!i.isSuccess()) return Failure(i.getParameters()[0]);
      var ev:EnumValueDefinitionNode = { kind:Kind.NAMED_TYPE, name:mkNameNode(i.sure()) };
      def.values.push(ev);
      skipWhitespace(true);
      if (allow('}')) break;
    }
    def.loc.end = pos;

    skipWhitespace(true);
    return Success(def);
  }

  private function readUnionDefinition(start:Int):Outcome<BaseNode, Err>
  {
    var def:UnionTypeDefinitionNode = {
      loc: { start:start, end:pos, source:_filename, startToken:null, endToken:null },
      kind:Kind.UNION_TYPE_DEFINITION,
      name:null,
      types:[]
    };
    skipWhitespace(true);
    var name:String = ident().sure();
    def.name = mkNameNode(name);
    skipWhitespace(true);

    expect('=');
    while (true) {
      skipWhitespace(true);
      var i = ident();
      if (!i.isSuccess()) return Failure(i.getParameters()[0]);
      var u_type:NamedTypeNode = { kind:Kind.NAMED_TYPE, name:mkNameNode(i.sure()) };
      def.types.push(u_type);
      if (!allow('|')) break;
    }
    def.loc.end = pos;

    skipWhitespace(true);
    return Success(def);
  }

  private function readFieldDefinition()
  {
    skipWhitespace(true);
    var def:FieldDefinitionNode = {
      loc: { start:pos, end:pos, source:_filename, startToken:null, endToken:null },
      kind:Kind.OBJECT_TYPE_DEFINITION,
      name:null,
      type:null,
      arguments:[],
      directives:[]
    };
    
    var list_wrap = false;
    var inner_not_null = false;
    var outer_not_null = false;
    var name:String = ident().sure();
    def.name = mkNameNode(name);
    //TODO: ( ... queries ? )
    expect(':');
    if (allow('[')) list_wrap = true;
    skipWhitespace();
    var i = ident();
    if (!i.isSuccess()) { return Failure(i.getParameters()[0]); }
    var named_type:NamedTypeNode = { kind:Kind.NAMED_TYPE, name:mkNameNode(i.sure()) }
    skipWhitespace();
    if (list_wrap) {
      if (allow('!')) inner_not_null = true;
      skipWhitespace();
      expect(']');
    }
    skipWhitespace();
    if (allow('!')) outer_not_null = true;

    // Wrap the NamedTypeNode in List and/or NonNull wrappers
    var t:TypeNode = def;
    if (outer_not_null) {
      t.type = cast { type:null, kind:Kind.NON_NULL_TYPE };
      t = t.type;
    }
    if (list_wrap) {
      t.type = cast { type:null, kind:Kind.LIST_TYPE };
      t = t.type;
    }
    if (inner_not_null) {
      t.type = cast { type:null, kind:Kind.NON_NULL_TYPE };
      t = t.type;
    }
    t.type = cast named_type;
    def.loc.end = pos;
    skipWhitespace(true);
    return Success(def);
  }
  //function kwd(name:String) {
  //  var pos = pos;
  //  
  //  var found = switch ident(true) {
  //    case Success(v) if (v == name): true;
  //    default: false;
  //  }
  //  
  //  if (!found) this.pos = pos;
  //  return found;
  //}

  private inline function fail(msg) return Failure(makeError(msg, makePos(pos)));

  static var IDENT_START = UPPER || LOWER || '_'.code;
  static var IDENT_CONTD = IDENT_START || DIGIT;

  private function ident(here = false) {
    return 
      if ((here && is(IDENT_START)) || (!here && upNext(IDENT_START)))
        Success(readWhile(IDENT_CONTD));
      else 
        Failure(makeError('Identifier expected', makePos(pos)));  
  }

  private inline function skipWhitespace(and_comments:Bool=false) {
    doReadWhile(WHITE);
    if (and_comments) {
      while (true) {
        if (is(COMMENT_CHAR)) { upto("\n"); } else { break; }
        doReadWhile(WHITE);
      }
    }
  }

  override function doSkipIgnored() skipWhitespace();
  
  override function doMakePos(from:Int, to:Int):Pos
  {
    return { file:'Untitled', min:from, max:to };
  }

  override function makeError(message:String, pos:Pos):Err
  {
    return { message:message, pos:pos };
  }
}
