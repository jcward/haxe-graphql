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
  private var _source:String;

  public function new(schema:String, ?source:String)
  {
    super(schema);
    _source = source;
    document = readDocument();
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
          trace('success, read def $d!');
          defs.push(d);
        case Failure(f):
          throw makeError(f.message, makePos(pos));
      }
    }
    return { definitions:defs };
  }

  function readDefinition():Outcome<BaseNode, Err>
  {
    skipWhitespace(true);
    var p = pos;
    var rtn:Outcome<BaseNode, Err> = switch ident(true) {
      case Success(v) if (v=="type"): readTypeDefinition(p);
      case Success(v) if (v=="enum"): Success(readEnumDefinition(p));
      case Success(_): Failure(makeError('Got "${ source[p...pos] }", expecting keyword: type enum schema union interface', makePos(p)));
      case Failure(e): Failure(e);
    }
    return rtn;
  }

  function readTypeDefinition(start:Int):Outcome<BaseNode, Err> {
    var def:ObjectTypeDefinitionNode = {
      loc: { start:start, end:start, source:_source },
      kind:Kind.OBJECT_TYPE_DEFINITION,
      name:null,
      interfaces:[],
      fields:[]
    };
    skipWhitespace(true);
    var name:String = ident().sure();
    def.name = mkNameNode(name);
    skipWhitespace(true);

    // TODO: parse: implements IF1 & IF2

    if (!is('{'.code)) return Failure(makeError('Got "${ source[pos...pos+1] }", expecting "{"', makePos(pos)));
    
    while (true) {
      switch readFieldDefinition() {
        case Success(field): def.fields.push(field);
        case Failure(e): return Failure(e);
      }
    }
    if (!is('}'.code)) return Failure(makeError('Got "${ source[pos...pos+1] }", expecting "}"', makePos(pos)));
    def.loc.end = pos;

    skipWhitespace(true);

    return Success(def);
  }
  function mkNameNode(name:String) return { kind:Kind.NAMED_TYPE, value:name, loc:null };
  function readEnumDefinition(start:Int):BaseNode return null;

  function readFieldDefinition()
  {
    skipWhitespace(true);
    var def:FieldDefinitionNode = {
      loc: { start:pos, end:pos, source:_source },
      kind:Kind.OBJECT_TYPE_DEFINITION,
      name:null,
      type:null,
      arguments:[],
      directives:[]
    };
    
    var list_wrap = false;
    var inner_not_null = false;
    var outer_not_null = false;
    def.name = mkNameNode(ident().sure());
    skipWhitespace();
    //TODO: ( ... queries ? )
    if (!is(':'.code)) return fail('Got "${ source[pos...pos+1] }", expecting "}"');
    skipWhitespace();
    if (is('['.code)) list_wrap = true;
    skipWhitespace();
    var named_type:NamedTypeNode = { kind:Kind.NAMED_TYPE, name:mkNameNode(ident().sure()) }
    skipWhitespace();
    if (list_wrap) {
      if (is('!'.code)) inner_not_null = true;
      skipWhitespace();
      expect(']');
    }
    skipWhitespace();
    if (is('!'.code)) outer_not_null = true;

    // Wrap the NamedTypeNode in List and/or NonNull wrappers
    var t:TypeNode = def;
    if (outer_not_null) {
      t.type = ({ type:null, kind:Kind.NON_NULL_TYPE }:NonNullTypeNode);
      t = t.type;
    }
    if (list_wrap) {
      t.type = ({ type:null, kind:Kind.LIST_TYPE }:ListTypeNode);
      t = t.type;
    }
    if (inner_not_null) {
      t.type = ({ type:null, kind:Kind.NON_NULL_TYPE }:NonNullTypeNode);
      t = t.type;
    }
    t.type = named_type;
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
