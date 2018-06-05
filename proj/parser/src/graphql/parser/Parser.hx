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

    document = switch parseDocument() {
      case Success(d): d;
      case Failure(f):
      format_and_rethrow(f);
      null;
    };
  }


  /* - - - - - - - - - - - -
     - - - - - - - - - - - -
     Helpers
     - - - - - - - - - - - -
     - - - - - - - - - - - - */

  static var COMMENT_CHAR = '#'.code;
  static var EXP = @:privateAccess tink.parse.Filter.ofConst('e'.code) || @:privateAccess tink.parse.Filter.ofConst('E'.code);
  static var IDENT_START = UPPER || LOWER || '_'.code;
  static var IDENT_CONTD = IDENT_START || DIGIT;

  private function ident(error_msg:String='Identifier expected') {
    var here = false;
    return 
      if ((here && is(IDENT_START)) || (!here && upNext(IDENT_START)))
        Success(readWhile(IDENT_CONTD));
      else 
        Failure(makeError(error_msg, makePos(pos)));  
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

  function mkLoc(?start:Int, ?end:Int):Location
  {
    if (start==null) start = pos;
    if (end==null) end = start;
    return { start:start, end:end, source:_filename, startToken:null, endToken:null };
  }

  function format_and_rethrow(e:Err)
  {
    var line_num = 1;
    var off = 0;
    for (i in 0...e.pos.min) if (source.fastGet(i)=="\n".code) {
      off = i;
      line_num++;
    }
    // Line number error message
    var msg = '$_filename:$line_num: characters ${ e.pos.min-off }-${ e.pos.max-off } Error: ${ e.message }';
    throw msg;
  }


  /* - - - - - - - - - - - -
     - - - - - - - - - - - -
     Schema parsing
     - - - - - - - - - - - -
     - - - - - - - - - - - - */

  private function parseDocument():Outcome<Document, Err>
  {
    var defs = [];
    while (true) {
      skipWhitespace(true);

      if (done()) break;

      switch readDefinition() {
        case Success(d): defs.push(d);
        case Failure(f): return Failure(f);
      }
    }
    return Success({ definitions:defs });
  }

  private function readDefinition():Outcome<BaseNode, Err>
  {
    skipWhitespace(true);
    var start = pos;

    if (is('{'.code)) {
      return parseOperationDefinition(start, 'query');
    }
    var id = { var o = ident(); !o.isSuccess() && return o.swap(null); o.sure(); };

    // See official parser, list of valid identifiers here:
    // https://github.com/graphql/graphql-js/blob/dd0297302800347a20a192624ba6373ee86836a3/src/language/parser.js#L205
    var rtn:Outcome<BaseNode, Err> = switch id.toString() {
      case "type":      parseTypeDefinition(start, Kind.OBJECT_TYPE_DEFINITION);
      case "interface": parseTypeDefinition(start, Kind.INTERFACE_TYPE_DEFINITION);
      case "schema":    parseSchemaDefinition(start);
      case "enum":      parseEnumDefinition(start);
      case "union":     parseUnionDefinition(start);
      case "scalar":    parseScalarDefinition(start);

      case "query" | "mutation":     parseOperationDefinition(start, id);

      default:
        Failure(makeError('Got "${ source[start...pos] }", expecting keyword: type interface enum schema union', makePos(start)));
    }
    return rtn;
  }

  private function parseTypeDefinition(start:Int, kind:String):Outcome<BaseNode, Err>
  {
    var def:TypeDefinitionNode = { loc:mkLoc(), kind:kind };

    var is_interface = def.kind==Kind.INTERFACE_TYPE_DEFINITION;

    var name = parseNameNode();
    if (!name.isSuccess()) return Failure(name.getParameters()[0]);
    (cast def).name = name.sure();
    skipWhitespace(true);

    var interfaces = [];
    skipWhitespace(true);

    var err:Outcome<BaseNode, Err> = null;
    if (allow('implements')) {
      if (is_interface) return return Failure(makeError('Interfaces cannot implement interfaces.', makePos(pos)));
      parseRepeatedly(function():Void {
        var name = parseNameNode();
        if (!name.isSuccess()) err = Failure(name.getParameters()[0]);
        var if_type:NamedTypeNode = { kind:Kind.NAMED_TYPE, name:name.sure() };
        interfaces.push(if_type);
      }, {end:'{', sep:'&', allowTrailing:false});
    } else {
      expect('{');
    }
    if (err!=null) return err;

    var fields = (cast def).fields = [];
    while (true) {
      switch parseFieldDefinition() {
        case Success(field): fields.push(field);
        case Failure(e): return Failure(e);
      }
      if (allow('}')) break;
    }
    def.loc.end = pos;

    skipWhitespace(true);

    if (is_interface) {
      var inode:InterfaceTypeDefinitionNode = cast def;
      return Success(inode);
    } else {
      var onode:ObjectTypeDefinitionNode = {
        name:name.sure(), loc:def.loc, kind:def.kind, fields:fields, interfaces:interfaces
      };
      return Success(onode);
    }
  }

  private function parseSchemaDefinition(start:Int):Outcome<SchemaDefinitionNode, Err>
  {
    var def:SchemaDefinitionNode = { loc:mkLoc(), kind:Kind.SCHEMA_DEFINITION, operationTypes:[], directives:null };

    skipWhitespace(true);
    expect('{');
    skipWhitespace(true);
    while (true) {
      if (is(IDENT_START)) {
        var loc_start = pos;
        var id = ident();
        skipWhitespace(true);
        var ntn_start = pos;
        var ntn_out = parseType();
        if (!ntn_out.isSuccess()) return Failure(ntn_out.getParameters()[0]);
        if (ntn_out.sure().kind!=Kind.NAMED_TYPE) return Failure(makeError('Expecting named type', makePos(ntn_start)));
        var id_s = id.sure().toString();
        switch id_s {
          case "query" | "mutation": //  | "subscription": Apparently subscription is experimental / non-spec
            var n:OperationTypeDefinitionNode = { kind:Kind.OPERATION_TYPE_DEFINITION, operation:id_s, type:ntn_out.sure() };
            def.operationTypes.push(n);
          default: return Failure(makeError('Unknown operation type ${ id_s }', makePos(loc_start)));
        }
      } else {
        skipWhitespace(true);
        expect('}');
        break;
      }
    }

    return Success(def);
  }

  private function parseNameNode(skip_whitespace:Bool=true):Outcome<NameNode, Err>
  {
    if (skip_whitespace) skipWhitespace(true);
    var start = pos;
    return try {
      var name:String = ident().sure();
      var loc = { start:start, end:pos, source:_filename, startToken:null, endToken:null };
      Success({ kind:Kind.NAMED_TYPE, value:name, loc:loc });
    } catch (e:Dynamic) {
      Failure(makeError('Name identifier expected', makePos(pos)));  
    }
  }

  private function parseEnumDefinition(start:Int):Outcome<BaseNode, Err>
  {
    var def:EnumTypeDefinitionNode = {
      loc: { start:start, end:pos, source:_filename, startToken:null, endToken:null },
      kind:Kind.ENUM_TYPE_DEFINITION,
      name:null,
      values:[]
    };

    var name = parseNameNode();
    if (!name.isSuccess()) return Failure(name.getParameters()[0]);
    def.name = name.sure();
    skipWhitespace(true);

    expect('{');
    while (true) {
      var name = parseNameNode();
      if (!name.isSuccess()) return Failure(name.getParameters()[0]);
      var ev:EnumValueDefinitionNode = { kind:Kind.NAMED_TYPE, name:name.sure() };
      def.values.push(ev);
      skipWhitespace(true);
      if (allow('}')) break;
    }
    def.loc.end = pos;

    skipWhitespace(true);
    return Success(def);
  }

  private function parseScalarDefinition(start:Int):Outcome<BaseNode, Err>
  {
    var def:ScalarTypeDefinitionNode = {
      loc: { start:start, end:pos, source:_filename, startToken:null, endToken:null },
      kind:Kind.SCALAR_TYPE_DEFINITION,
      name:null
    };
    skipWhitespace(true);
    var name = parseNameNode();
    if (!name.isSuccess()) return Failure(name.getParameters()[0]);
    def.name = name.sure();
    def.loc.end = pos;
    skipWhitespace(true);
    return Success(def);
  }

  private function parseUnionDefinition(start:Int):Outcome<BaseNode, Err>
  {
    var def:UnionTypeDefinitionNode = {
      loc: { start:start, end:pos, source:_filename, startToken:null, endToken:null },
      kind:Kind.UNION_TYPE_DEFINITION,
      name:null,
      types:[]
    };
    var name = parseNameNode();
    if (!name.isSuccess()) return Failure(name.getParameters()[0]);
    def.name = name.sure();
    skipWhitespace(true);

    expect('=');
    while (true) {
      var name = parseNameNode();
      if (!name.isSuccess()) return Failure(name.getParameters()[0]);
      var u_type:NamedTypeNode = { kind:Kind.NAMED_TYPE, name:name.sure() };
      def.types.push(u_type);
      if (!allow('|')) break;
    }
    def.loc.end = pos;

    skipWhitespace(true);
    return Success(def);
  }

  private function parseFieldDefinition()
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

    var name = parseNameNode();
    if (!name.isSuccess()) return Failure(name.getParameters()[0]);
    def.name = name.sure();

    if (allow('(')) {
      var args = parseArgumentDefs();
      if (!args.isSuccess()) return Failure(args.getParameters()[0]);
      def.arguments = args.sure();
    }

    skipWhitespace();
    var type = parseType();
    if (!type.isSuccess()) return Failure(type.getParameters()[0]);
    def.type = cast type.sure();

    def.loc.end = pos;
    skipWhitespace(true);
    return Success(def);
  }

  private function parseType():Outcome<graphql.TypeNode, Err>
  {
    var list_wrap = false;
    var inner_not_null = false;
    var outer_not_null = false;

    expect(':');
    if (allow('[')) list_wrap = true;
    var name = parseNameNode();
    if (!name.isSuccess()) return Failure(name.getParameters()[0]);
    var named_type:NamedTypeNode = { kind:Kind.NAMED_TYPE, name:name.sure() }
    skipWhitespace();
    if (list_wrap) {
      if (allow('!')) inner_not_null = true;
      skipWhitespace();
      expect(']');
    }
    skipWhitespace();
    if (allow('!')) outer_not_null = true;

    // Wrap the NamedTypeNode in List and/or NonNull wrappers
    var type:TypeNode = null;
    var ref:TypeNode = null;
    function update_ref(t:TypeNode) {
      if (type==null) {
        type = t;
        ref = t;
      } else {
        ref.type = t;
        ref = t;
      }
    }

    if (outer_not_null) update_ref(cast { type:null, kind:Kind.NON_NULL_TYPE });
    if (list_wrap) update_ref({ type:null, kind:Kind.LIST_TYPE });
    if (inner_not_null) update_ref({ type:null, kind:Kind.NON_NULL_TYPE } );
    update_ref(cast named_type);

    return Success(type);
  }

  private function parseArgumentDefs():Outcome<Array<graphql.InputValueDefinitionNode>, Err>
  {
    var args = [];

    while (true) {
      var iv:graphql.InputValueDefinitionNode = {
        type : null, // graphql.TypeNode,
        name : null, // graphql.NameNode,
        loc : null, // Null<graphql.Location>,
        kind : Kind.INPUT_VALUE_DEFINITION, // String,
        directives : null,  // Null<graphql.ReadonlyArray<graphql.DirectiveNode>>,
        description : null, // Null<graphql.StringValueNode>,
        defaultValue : null // Null<graphql.ValueNode>
      };
      var name = parseNameNode();
      if (!name.isSuccess()) return Failure(name.getParameters()[0]);
      iv.name = name.sure();

      skipWhitespace(true);
      var type = parseType();
      if (!type.isSuccess()) return Failure(type.getParameters()[0]);
      iv.type = cast type.sure();

      args.push(iv);

      skipWhitespace(true);
      if (allow(')')) break;

      skipWhitespace(true);
      if (allow('=')) {
        iv.defaultValue = { var o = parseValue(); !o.isSuccess() && return o.swap(null); o.sure(); };
      }

      skipWhitespace(true);
      if (allow(')')) break;
      expect(',');
    }

    return Success(args);
  }


  /* - - - - - - - - - - - -
     - - - - - - - - - - - -
     Value Parsing
     - - - - - - - - - - - -
     - - - - - - - - - - - - */

  private function parseValue():Outcome<ValueNode, Err>
  {
    //  typedef IntValueNode >  value: String,
    //  typedef FloatValueNode >  value: String,
    //  typedef StringValueNode >  value: String,  ?block: Bool,
    //  typedef BooleanValueNode >  value: Bool,
    //  typedef NullValueNode 
    //  typedef EnumValueNode >  value: String,
    //  typedef ListValueNode >  values: ReadonlyArray<ValueNode>,
    //  typedef ObjectValueNode > fields: ReadonlyArray<ObjectFieldNode>, // name:value

    skipWhitespace(true);
    var start:Int = pos;

    try {
      var num = parseNumeric();
      if (num!=null) {
        var v = {
          kind:num.is_float ? Kind.FLOAT : Kind.INT,
          value:num.value
        };
        return Success(cast v);
      }

      var str = parseString();
      if (str!=null) {
        var v = { value:str.value, block:str.is_block };
        return Success(cast v);
      }

      if (allow('$')) {
        var v = { var o = parseVariableNode(start); !o.isSuccess() && return o.swap(null); o.sure(); };
        return Success(v);
      }

      if (allowHere('true')) return Success(cast { kind:Kind.BOOLEAN, value:true });
      if (allowHere('false')) return Success(cast { kind:Kind.BOOLEAN, value:false });
      if (allowHere('null')) return Success(cast { kind:Kind.NULL, value:false });
      if (is(IDENT_START)) return Success(cast { kind:Kind.ENUM, value:ident() });

      if (is('['.code)) return Success(cast { kind:Kind.LIST, values:parseArrayValues() });
      if (is('{'.code)) return Success(cast { kind:Kind.OBJECT, fields:parseObjectFields() });
    } catch (e:Err) {
      return Failure(e);
    }

    return Failure(makeError('Expected value but found ${ String.fromCharCode(source.get(pos)) }', makePos(pos)));
  }

  private function parseNumeric():Null<{ value:String, is_float:Bool}>
  {
    // http://facebook.github.io/graphql/draft/#sec-Int-Value
    var reset = pos;
    var negative = allowHere('-');
    var is_float = false;
    var num:String = readWhile(DIGIT);
    if (num==null || num.length==0) {
      pos = reset;
      return null;
    }
    if (negative) num = '-'+num;
    var dot = allowHere('.');
    if (dot) {
      is_float = true;
      num += '.';
      num += readWhile(DIGIT);
    }
    var exp = is(EXP) ? 'e' : null;
    if (exp!=null) {
      is_float = true;
      num += 'e'; pos++;
      var neg_exp = allowHere('-');
      var eval = readWhile(DIGIT);
      if (eval.length!=1) throw makeError('Invalid exponent ${ eval }', makePos(pos));
      num += (neg_exp ? '-' : '') + eval;
    }
    return { value:num, is_float:is_float };
  }

  private function parseString():Null<{ value:String, is_block:Bool}>
  {
    // http://facebook.github.io/graphql/draft/#sec-String-Value
    var reset = pos;
    var is_quote = allowHere('"');
    if (!is_quote) {
      pos = reset;
      return null;
    }

    // TODO: Unicode? block strings?
    var is_block = allowHere('""');
    var last_char:Int = 0;
    var str = new StringBuf();

    while (true) {
      if (pos==source.length) throw makeError('Unterminated string', makePos(reset));
      var char = source.fastGet(pos++);

      // quote, test if it's an exit
      if (char=='"'.code) { // quote
        if (last_char!='\\'.code) { // not an escaped quote
          if (!is_block) break;
          // peek forward block break
          if (is_block && source.get(pos)=='"'.code && source.get(pos+1)=='"'.code) {
            pos = pos + 2;
            break;
          }
        }
      }
      last_char = char;
      // TODO: what about r f b?
      if (!is_block && char==13) str.add("\\n");
      else if (!is_block && char==9) str.add("\\t");
      else str.addChar(char);
    }

    return { value:str.toString(), is_block:is_block };
  }

  private function parseArrayValues():Array<ValueNode>
  {
    var values = [];
    expect('[');
    if (allow(']')) return values;
    while(true) {
      var val = parseValue();
      if (!val.isSuccess()) throw makeError(val.getParameters()[0], makePos(pos));
      values.push(val.sure());
      skipWhitespace(true);
      if (allow(']')) break;
      expect(',');
    }
    return values;
  }

  private function parseObjectFields():Array<ObjectFieldNode>
  {
    var fields = [];
    expect('{');
    if (allow('}')) return fields;
    while (true) {
      skipWhitespace(true);
      var key = parseString();
      if (key==null) throw makeError('Expecting object key', makePos(pos));
      if (key.is_block) throw makeError('Object keys don\'t support block strings', makePos(pos));
      skipWhitespace(true);
      expect(':');
      var val = parseValue();
      if (!val.isSuccess()) throw makeError(val.getParameters()[0], makePos(pos));
      var nn:NameNode = { kind:Kind.NAME, value:key.value };
      var of:ObjectFieldNode = { kind:Kind.OBJECT_FIELD, name:nn, value:val.sure() };
      fields.push(of);
      if (allow('}')) break;
      expect(',');
    }
    return fields;
  }

  /* - - - - - - - - - - - -
     - - - - - - - - - - - -
     Operation Parsing
     - - - - - - - - - - - -
     - - - - - - - - - - - - */

  private function parseOperationDefinition(start:Int, operation:String): Outcome<OperationDefinitionNode, Err>
  {
    var def:OperationDefinitionNode = {
      kind:Kind.OPERATION_DEFINITION,
      operation:operation,
      name:null,
      variableDefinitions:null,
      directives:[],
      selectionSet:null,
      loc:mkLoc(pos)
    };

    skipWhitespace(true);

    if (!is('{'.code)) { // named query
      def.name = { var o = parseNameNode(); !o.isSuccess() && return o.swap(null); o.sure(); };
      var vds = { var o = parseVariableDefinitions(); !o.isSuccess() && return o.swap(null); o.sure(); };
      def.variableDefinitions = vds;
      // TODO: def.directives = parseDirectives
    }
    expect('{');

    def.selectionSet = { var o = parseSelectionSet(); !o.isSuccess() && return o.swap(null); o.sure(); };

    return Success(def);
  }

  function parseVariableNode(start:Int):Outcome<VariableNode, Err> {
    var name = { var o = parseNameNode(); !o.isSuccess() && return o.swap(null); o.sure(); };
    var v:VariableNode = { kind:Kind.VARIABLE, name: name, loc:mkLoc(start,pos) };
    return Success(v);
  }

  function parseVariableDefinitions(): Outcome<Array<VariableDefinitionNode>, Err> {
    skipWhitespace(true);
    if (!allow('(')) return Success([]);

    // Unscoped: not called from anywhere else
    function parseVariableDefinition():Outcome<VariableDefinitionNode, Err> {
      expect('$');
      var start = pos;
      var v = { var o = parseVariableNode(start); !o.isSuccess() && return o.swap(null); o.sure(); };

      var type = { var o = parseType(); !o.isSuccess() && return o.swap(null); o.sure(); };

      var vd:VariableDefinitionNode = {
        kind:Kind.VARIABLE_DEFINITION,
        type:type,
        variable:v,
        loc:null
      }

      if (allow('=')) {
        vd.defaultValue = { var o = parseValue(); !o.isSuccess() && return o.swap(null); o.sure(); };
      }

      return Success(vd);
    }

    var var_defs = [];
    while (true) {
      var vd = { var o = parseVariableDefinition(); !o.isSuccess() && return o.swap(null); o.sure(); };
      var_defs.push(vd);
      if (!allow(',')) break;
    }
    expect(')');
    return Success(var_defs);
  }

  function parseSelectionSet(): Outcome<SelectionSetNode, Err> {
    skipWhitespace(true);
    var start_ss = pos;

    // Unscoped: not called from anywhere else
    //   selection == FragmentSpead | Field | InlineFragment
    // https://github.com/graphql/graphql-js/blob/dd0297302800347a20a192624ba6373ee86836a3/src/language/parser.js#L337-L347
    function parseSelection():Outcome<FieldNode, Err>
    {
      if (allow('...')) throw 'TODO: return parseFragment';

      var start = pos;
      var name = { var o = parseNameNode(); !o.isSuccess() && return o.swap(null); o.sure(); };
      var alias = null;
      if (allow(':')) {
        alias = name;
        name = { var o = parseNameNode(); !o.isSuccess() && return o.swap(null); o.sure(); };
      }

      var f:FieldNode = { kind:Kind.FIELD, name:name, loc:mkLoc(start) };
      f.arguments = { var o = parseArguments(); !o.isSuccess() && return o.swap(null); o.sure(); };
      f.directives = []; // TODO: directives
      if (allow('{')) {
        f.selectionSet = { var o = parseSelectionSet(); !o.isSuccess() && return o.swap(null); o.sure(); };
      }

      f.loc.end = pos;
      return Success(f);
    }

    var sset = [];
    while (true) {
      skipWhitespace(true);
      var sel = { var o = parseSelection(); !o.isSuccess() && return o.swap(null); o.sure(); };
      sset.push(sel);
      if (allow('}')) break;
    }

    var ssnode = { kind:Kind.SELECTION_SET, selections:sset, loc:mkLoc(start_ss, pos) };
    return Success(ssnode);
  }

  function parseArguments(): Outcome<Array<ArgumentNode>, Err> {
    skipWhitespace(true);
    if (!allow('(')) return Success([]);

    // Unscoped
    function parseArgument(): Outcome<ArgumentNode, Err> {
      var an:ArgumentNode = { kind:Kind.ARGUMENT, name:null, value:null };
      an.name = { var o = parseNameNode(); !o.isSuccess() && return o.swap(null); o.sure(); };
      if (allow(':')) {
        an.value = { var o = parseValue(); !o.isSuccess() && return o.swap(null); o.sure(); };
      }
      return Success(an);
    }

    var args = [];
    while (true) {
      var an = { var o = parseArgument(); !o.isSuccess() && return o.swap(null); o.sure(); };
      args.push(an);
      if (allow(')')) break;
    }

    return Success(args);
  }
}
