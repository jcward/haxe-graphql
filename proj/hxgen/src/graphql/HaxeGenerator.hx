package graphql;

import graphql.ASTDefs;
import haxe.ds.Either;

using Lambda;

@:enum abstract GenerateOption(String) {
  var TYPEDEFS = 'typedefs';
  var CLASSES = 'classes';
}

typedef HxGenOptions = {
  ?generate:GenerateOption,
  ?disable_null_wrappers:Bool
}

typedef SchemaMap = {
  query_type:String,
  mutation_type:String
}

// key String is field_name
typedef InterfaceType = haxe.ds.StringMap<TypeStringifier>;

typedef SomeNamedNode = { kind:String, name:NameNode };

@:expose
class HaxeGenerator
{
  private var _stdout_writer:StringWriter;
  private var _stderr_writer:StringWriter;
  private var _interfaces = new ArrayStringMap<InterfaceType>();
  private var _options:HxGenOptions;

  public static function parse(doc:DocumentNode,
                               ?options:HxGenOptions,
                               throw_on_error=true):{ stdout:String, stderr:String }
  {
    var result = { stdout:'', stderr:'' };

    // Check for options / init errors
    var gen = new HaxeGenerator(options);
    if (!gen._stderr_writer.is_empty()) {
      result.stderr = gen._stderr_writer.toString();
    } else {
      result = gen.parse_document(doc);
    }

    if (throw_on_error && result.stderr.length>0) {
      throw result.stderr;
    }

    return result;
  }

  // Private constructor simply because, once parsed, the generator's state
  // is "dirty", it should be considered "consumed". So use a static
  // helper (above).
  private function new(?options:HxGenOptions)
  {
    _stdout_writer = new StringWriter();
    _stderr_writer = new StringWriter();
    init_options(options);
  }

  private function init_options(?options:HxGenOptions)
  {
    _options = options==null ? {} : options;
    if (_options.generate==null) _options.generate = TYPEDEFS;
    if (_options.disable_null_wrappers==null) _options.disable_null_wrappers = false;
  }

  private function handle_args(type_path:Array<String>, args:FieldArguments) {
    if (args==null || args.length==0) return;
    for (a in args) {
      var args_name = 'Args_${ type_path.join('Dot') }_${ a.field }';
      var args_obj:ObjectTypeDefinitionNode = {
        kind:Kind.OBJECT_TYPE_DEFINITION,
        name:{ value:args_name, kind:Kind.NAME },
        fields:cast a.arguments
      };
      write_haxe_typedef(args_obj);
    }
  }

  private function handle_variables(opv:OpVariables) {
    if (opv==null || opv.variables==null || opv.variables.length==0) return;
    var fields:Array<FieldDefinitionNode> = [];
    for (v in opv.variables) {
      fields.push({
        kind:Kind.FIELD_DEFINITION,
        type:v.type,
        name:v.variable.name
      });
    }
    var vars_obj:ObjectTypeDefinitionNode = {
      kind:Kind.OBJECT_TYPE_DEFINITION,
      name:{ value:'OP_${ opv.op_name }_Vars', kind:Kind.NAME },
      fields:fields
    };
    write_haxe_typedef(vars_obj);
  }

  // Parse a graphQL AST document, generating Haxe code
  private function parse_document(doc:DocumentNode) {
    // Parse definitions
    init_base_types();

    function newline() _stdout_writer.append('');

    var root_schema:SchemaMap = null;

    // First pass: parse interfaces and schema def only
    // - when outputing typedefs, types will "> extend" interfaces, removing duplicate fields
    // - TODO: is this proper behavior? Or can type field be a super-set of the interface field?
    //         see spec: http://facebook.github.io/graphql/October2016/#sec-Object-type-validation
    //         "The object field must be of a type which is equal to or a sub‐type of the
    //          interface field (covariant)."
    for (def in doc.definitions) {
      switch (def.kind) {
        // case ASTDefs.Kind.INTERFACE_TYPE_DEFINITION:
        //   var args = write_interface_as_haxe_base_typedef(cast def);
        //   newline();
        //   handle_args([get_def_name(cast def)], args);
        case ASTDefs.Kind.SCHEMA_DEFINITION:
          if (root_schema!=null) error('Error: cannot specify two schema definitions');
          root_schema = write_schema_def(cast def);
          newline();
        case _:
      }
    }

    // Second pass: parse everything else
    for (def in doc.definitions) {
      switch (def.kind) {
      case ASTDefs.Kind.SCHEMA_DEFINITION:
        // null op, handled above
      case ASTDefs.Kind.SCALAR_TYPE_DEFINITION:
        write_haxe_scalar(cast def);
        newline();
      case ASTDefs.Kind.ENUM_TYPE_DEFINITION:
        write_haxe_abstract_enum(cast def);
        newline();
      case ASTDefs.Kind.OBJECT_TYPE_DEFINITION:
        var args = write_haxe_typedef(cast def);
        newline();
        handle_args([get_def_name(cast def)], args);
      case ASTDefs.Kind.UNION_TYPE_DEFINITION:
        write_union_as_haxe_abstract(cast def);
        newline();
      case ASTDefs.Kind.OPERATION_DEFINITION:
        // No-op, still generating type map
      case ASTDefs.Kind.INTERFACE_TYPE_DEFINITION:
        // TODO: anything special about Interfaces ?
        var args = write_haxe_typedef(cast def);
        newline();
        handle_args([get_def_name(cast def)], args);
      case ASTDefs.Kind.INPUT_OBJECT_TYPE_DEFINITION:
        // TODO: anything special about InputObjectTypeDefinition ?
        var args = write_haxe_typedef(cast def);
        newline();
        handle_args([get_def_name(cast def)], args);
      default:
        var name = (cast def).name!=null ? (' - '+(cast def).name.value) : '';
        error('Error: unknown / unsupported definition kind: '+def.kind+name);
      }
    }

    // Third pass: write operation results
    for (def in doc.definitions) switch def.kind {
      case ASTDefs.Kind.OPERATION_DEFINITION:
        var vars = write_operation_def_result(root_schema, doc, cast def);
        newline();
        handle_variables(vars);
      default:
    }

    return {
      stderr:_stderr_writer.toString(),
      stdout:_stdout_writer.toString()
    };
  }

  private function get_def_name(def) return def.name.value;

  public function toString() return _stdout_writer.toString();

  private function error(s:String) _stderr_writer.append(s);

  private var referenced_types = [];
  function type_referenced(name) {
    if (referenced_types.indexOf(name)<0) referenced_types.push(name);
  }

  private var defined_types = [];
  private var type_map = new ArrayStringMap<{ name:String, ?fields:ArrayStringMap<TypeStringifier> }>();
  function type_defined(name:String, fields:ArrayStringMap<TypeStringifier>=null) {
    if (defined_types.indexOf(name)<0) defined_types.push(name);
    type_map[name] = { name:name, fields:fields };
  }

  function parse_type(type:ASTDefs.TypeNode, parent:ASTDefs.TypeNode=null):TypeStringifier {
    var is_array = type.kind == ASTDefs.Kind.LIST_TYPE;
    var non_null = type.kind == ASTDefs.Kind.NON_NULL_TYPE;
    var wrapper = non_null || is_array;

    var optional = non_null ? false : (parent==null || parent.kind!=ASTDefs.Kind.NON_NULL_TYPE);
    var rtn:TypeStringifier = { prefix:'', suffix:'', child:null, optional:false };

    if (!wrapper) { // Leaf
      if (type.name==null) throw 'Expecting type.name!';
      if (type.type!=null) throw 'Not expecting recursive type!';
      if (type.kind!=ASTDefs.Kind.NAMED_TYPE) throw 'Expecting NamedType!';
      type_referenced(type.name.value);
      rtn.optional = optional;
      rtn.child = type.name.value;
    } else {
      if (type.type==null) throw 'Expecting recursive / wrapped type!';
      rtn.optional = optional;
      if (is_array) { rtn.prefix += 'Array<'; rtn.suffix += '>'; }
      rtn.child = parse_type(type.type, type);
    }

    return rtn;
  }

  /* -- TODO: REVIEW: http://facebook.github.io/graphql/October2016/#sec-Object-type-validation
                      sub-typing seems to be allowed... */
  function type0_equal_to_type1(type0:TypeStringifier, type1:TypeStringifier):Bool
  {
    // trace('STC: '+type0.toString(true)+' == '+type1.toString(true));
    return type0.toString(true)==type1.toString(true);
  }

  /**
   * @param {GraphQL.ObjectTypeDefinitionNode} def
   */
  function write_haxe_typedef(def:ASTDefs.ObjectTypeDefinitionNode):FieldArguments
  {
    var args:FieldArguments = [];

    // TODO: cli args for:
    //  - long vs short typedef format
    var short_format = true;

    // trace('Generating typedef: '+def.name.value);
    _stdout_writer.append('typedef '+def.name.value+' = {');

    var interface_fields_from = new ArrayStringMap<String>();
    var skip_interface_fields = new ArrayStringMap<TypeStringifier>();

//    if (def.interfaces!=null) {
//      for (intf in def.interfaces) {
//        var ifname = intf.name.value;
//        if (!_interfaces.exists(ifname)) throw 'Requested interface '+ifname+' (implemented by '+def.name.value+') not found';
//        var intf = _interfaces[ifname];
//        _stdout_writer.append('  /* implements interface */ > '+ifname+',');
//        for (field_name in intf.keys()) {
//          if (!skip_interface_fields.exists(field_name)) {
//            skip_interface_fields[field_name] = intf.get(field_name);
//            interface_fields_from[field_name] = ifname;
//          } else {
//            // Two interfaces could imply the same field name... in which
//            // case we need to ensure the "more specific" definition is kept.
//            if (!type0_equal_to_type1(intf.get(field_name), skip_interface_fields[field_name])) {
//              throw 'Type '+def.name.value+' inherits field '+field_name+' from multiple interfaces ('+ifname+', '+interface_fields_from[field_name]+'), the types of which do not match.';
//            }
//          }
//        }
//      }
//    }

    var fields = new ArrayStringMap<TypeStringifier>();
    type_defined(def.name.value, fields);

    for (field in def.fields) {
      // if (field.name.value=='id') debugger;
      var type = parse_type(field.type);
      var field_name = field.name.value;
      fields[field_name] = type.clone().follow();

      if (field.arguments!=null && field.arguments.length>0) {
        args.push({ field:field_name, arguments:field.arguments });
      }

      if (skip_interface_fields.exists(field_name)) {
        // Field is inherited from an interface, ensure the types match
        if (!type0_equal_to_type1(type, skip_interface_fields.get(field_name))) {
          throw 'Type '+def.name.value+' defines '+field_name+':'+type.toString(true)+', but Interface '+interface_fields_from[field_name]+' requires '+field_name+':'+interface_fields_from[field_name].toString();
        }
      } else {
        // Not inherited from an interface, include it in this typedef
        var type_str = '';
        var outer_optional = type.optional;
        type.optional = false;
        if (short_format) {
          // Outer optional gets converted to ?
          type_str = (outer_optional ? '?' : '') + field_name + ': '+type.toString(_options.disable_null_wrappers==true) + ',';
        } else {
          // Outer optional gets converted to @:optional
          type_str = (outer_optional ? '@:optional' : '') + 'var ' + field_name + ': ' + type.toString(_options.disable_null_wrappers==true) + ';';
        }
        _stdout_writer.append('  '+type_str);
      }
    }

    if (short_format) _stdout_writer.chomp_trailing_comma(); // Haxe doesn't care, but let's be tidy
    _stdout_writer.append('}');

    return args;
  }

//  function write_interface_as_haxe_base_typedef(def:ASTDefs.ObjectTypeDefinitionNode):FieldArguments
//  {
//    var args:FieldArguments = [];
//
//    if (def.name==null || def.name.value==null) throw 'Expecting interface must have a name';
//    var name = def.name.value;
//    if (_interfaces.exists(name)) throw 'Duplicate interface named '+name;
//
//    var intf = new ArrayStringMap<TypeStringifier>();
//    for (field in def.fields) {
//      var type = parse_type(field.type);
//      var field_name = field.name.value;
//      intf[field_name] = type;
//
//      if (field.arguments!=null && field.arguments.length>0) {
//        args.push({ field:field_name, arguments:field.arguments });
//      }
//    }
//
//    _interfaces[name] = intf;
//
//    // Generate the interface like a type
//    write_haxe_typedef(def);
//
//    return args;
//  }

  // TODO: optional?
  // function write_haxe_enum(def:ASTDefs.EnumTypeDefinitionNode) {
  //   // trace('Generating enum: '+def.name.value);
  //   type_defined(def.name.value);
  //   _stdout_writer.append('enum '+def.name.value+' {');
  //   for (enum_value in def.values) {
  //     _stdout_writer.append('  '+enum_value.name.value+';');
  //   }
  //   _stdout_writer.append('}');
  // }

  function write_haxe_abstract_enum(def:ASTDefs.EnumTypeDefinitionNode) {
    // trace('Generating enum: '+def.name.value);
    type_defined(def.name.value);
    _stdout_writer.append('@:enum abstract '+def.name.value+'(String) {');
    for (enum_value in def.values) {
      _stdout_writer.append('  var '+enum_value.name.value+' = "${enum_value.name.value}";');
    }
    _stdout_writer.append('}');
  }

  function write_haxe_scalar(def:ASTDefs.ScalarTypeDefinitionNode) {
    // trace('Generating scalar: '+def.name.value);
    type_defined(def.name.value);
    _stdout_writer.append('/* scalar ${ def.name.value } */\nabstract ${ def.name.value }(Dynamic) { }');
  }

  function write_union_as_haxe_abstract(def:ASTDefs.UnionTypeDefinitionNode) {
    // trace('Generating union (enum): '+def.name.value);
    type_defined(def.name.value);
    var union_types_note = def.types.map(function(t) return t.name.value).join(" | ");
    _stdout_writer.append('/* union '+def.name.value+' = ${ union_types_note } */');
    _stdout_writer.append('abstract '+def.name.value+'(Dynamic) {');
    for (type in def.types) {
      if (type.name==null) throw 'Expecting Named Type';
      var type_name = type.name.value;
      type_referenced(def.name.value);
      _stdout_writer.append(' @:from static function from${ type_name }(v:${ type_name }) return cast v;');
    }
    _stdout_writer.append('}');
  }

  // A schema definition is just a mapping / typedef alias to specific types
  function write_schema_def(def:ASTDefs.SchemaDefinitionNode):SchemaMap {
    var rtn = { query_type:null, mutation_type:null };

    _stdout_writer.append('/* Schema: */');
    for (ot in def.operationTypes) {
      var op = Std.string(ot.operation);
      switch op {
        case "query" | "mutation": //  | "subscription": is "non-spec experiment"
        var capitalized = op.substr(0,1).toUpperCase() + op.substr(1);
        _stdout_writer.append('typedef Schema${ capitalized }Type = ${ ot.type.name.value };');
        if (op=="query") rtn.query_type = ot.type.name.value;
        if (op=="mutation") rtn.mutation_type = ot.type.name.value;
        default: throw 'Unexpected schema operation: ${ op }';
      }
    }

    return rtn;
  }

  function resolve_type_path(path:Array<String>, ?op_name:String):ResolvedTypePath
  {
    var ptr:{ name:String, ?fields:ArrayStringMap<TypeStringifier> } = null;

    function array_inner_type(ts:TypeStringifier):String return switch ts.child {
      case Left(cts): cts.toString();
      default: null;
    } 

    var err_prefix = op_name!=null ? 'Error processing operation ${ op_name }: ' : "";

    var orig_path = path.join('.');
    var last_ts = null;
    while (path.length>0) {
      var name = path.shift();
      if (ptr==null) {
        ptr = type_map.get(name);
        if (ptr==null) throw '${ err_prefix }Didn\'t find root type ${ name }';
      } else {
        if (ptr.fields==null) throw '${ err_prefix }Expecting type ${ ptr.name } to have fields --> ${ name }!';
        var ts = ptr.fields.get(name);
        if (ts==null) throw '${ err_prefix }Expecting type ${ ptr.name } to have field ${ name }!';
        ts = ts.follow();
        last_ts = ts;
        if (path.length==0) break;
        var nm:String = ts.child;
        if (ts.prefix.indexOf('Array')>=0) nm = array_inner_type(ts);
        if (nm==null) throw '${ err_prefix }Expecting ts to have a name child -- is that not right?';
        ptr = type_map.get(nm);
        if (ptr==null) throw '${ err_prefix }Didn\'t find expected root type ${ nm }';
      }
    }

    // trace('Looking for ${ orig_path }, last_ts was ${ last_ts }');

    var is_list = last_ts.prefix.indexOf('Array')>=0;
    var is_opt = last_ts.optional;
    var type_string:String = is_list ? array_inner_type(last_ts) : last_ts.toString();

    var resolved = type_map[type_string];
    if (resolved==null) throw '${ err_prefix }Resolved ${ orig_path } to unknown type ${ type_string }';
    if (resolved.fields==null) {
      return LEAF(type_string, is_opt);
    } else {
      return TYPE(type_string, is_opt, is_list);
    }
  }

  function parse_op_for_fragment_unions(root_schema:SchemaMap,
                                        root:ASTDefs.DocumentNode,
                                        op_name:String,
                                        query_root_name:String,
                                        def:ASTDefs.OperationDefinitionNode):Void
  {
    // _stdout_writer.append('typedef OP_${ op_name }_Result = {');
    // handle_selection_set(op_name, def.selectionSet, [ query_root_name ], true);
    // _stdout_writer.append('}');
  }

  function gen_fragment_union(op_name:String,
                              sel_set:{ selections:Array<SelectionNode> },
                              type_path:Array<String>)
  {
    trace(op_name);
    trace(type_path);
    trace(sel_set);
    #if (js && debug) js.Lib.debug(); #end

    _stdout_writer.append('/* union for Query $op_name fragments at ${ type_path.join(".") } */');
    var union_name = 'QFrag_${ op_name }_${ type_path.join("_") }';
    var ud:UnionTypeDefinitionNode = {
        kind:Kind.UNION_TYPE_DEFINITION,
        name:{ value:union_name, kind:Kind.NAME },
        types:[]
    };
    var frags = sel_set.selections.filter(function(sel_node) return sel_node.kind.indexOf('Fragment')>=0);

    throw 'ARG, pick up fragment work here...';

    // It gets recursive, so we need to fix the issue of global _stdout_writer / side-effects :(

    // ud.
    // for (sel_node in sel_set) {
    //   sel
    // ud.types.push
    // write_union_as_haxe_abstract(ud);

  }

  function handle_selection_set(op_name:String,
                                sel_set:{ selections:Array<SelectionNode> },
                                type_path:Array<String>, // always abs
                                is_gen_fragments:Bool=false,
                                indent=1)
  {
    if (sel_set==null || sel_set.selections==null) {
      // Nothing left to do...
    }

    // No output for is_gen_fragments
    var output = is_gen_fragments ? new StringWriter() : _stdout_writer;

    var ind:String = '';
    for (i in 0...indent) ind += '  ';

    // If selection set has a fragment, it's result is a union type
    var has_fragment = sel_set.selections.find(function(sel_node) return sel_node.kind.indexOf('Fragment')>=0)!=null;
    if (has_fragment && is_gen_fragments) {
      throw 'TODO: FragmentSpread InlineFragment';
      gen_fragment_union(op_name, sel_set, type_path);
    }

    for (sel_node in sel_set.selections) {
      switch (sel_node.kind) { // FragmentSpead | Field | InlineFragment
      case Kind.FIELD:
        var field_node:FieldNode = cast sel_node;

        var name:String = field_node.name.value;
        var alias:String = field_node.alias==null ? name : field_node.alias.value;

        var next_type_path = type_path.slice(0);
        next_type_path.push(name);
        switch resolve_type_path(next_type_path, op_name) {
          case ROOT: throw 'Type path ${ type_path.join(",") } in query ${ op_name } should not resolve to root!';
          case LEAF(str, opt):
            if (field_node.selectionSet!=null) throw 'Cannot specify sub-fields of ${ str } in ${ type_path.join(",") } of operation ${ op_name }';
            var prefix = ind + (opt ? "?" : "");
            output.append('${ prefix }${ alias }:${ str },');
          case TYPE(str, opt, list):
            if (field_node.selectionSet==null) throw 'Must specify sub-fields of ${ str } in ${ type_path.join(",") } of operation ${ op_name }';
            var prefix = ind + (opt ? "?" : "");
            var suffix1 = (list ? 'Array<{' : '{') + ' /* subset of ${ str } */';
            var suffix2 = (list ? '}>,' : '},');
            output.append('$prefix$alias:$suffix1');
            handle_selection_set(op_name, field_node.selectionSet, [ str ], is_gen_fragments, indent+1);
            output.append('$ind$suffix2');
          }
  
        default:
          throw 'Unhandled SelectionNode kind: ${ sel_node.kind } (TODO: FragmentSpread InlineFragment)';
          if (is_gen_fragments) {
          } else {
          }

      }
    }
  }

  function write_operation_def_result(root_schema:SchemaMap,
                                      root:ASTDefs.DocumentNode,
                                      def:ASTDefs.OperationDefinitionNode):OpVariables
  {
    if (def.name==null || def.name.value==null) throw 'Only named operations are supported...';

    var op_name = def.name.value;

    _stdout_writer.append('/* Operation def: ${ op_name } */');

    if (def.operation!='query') throw 'Error processing ${ op_name }: Only queries are supported (mutation coming soon)...';

    var types:haxe.DynamicAccess<Dynamic> = {};

    var query_root_name = (root_schema==null || root_schema.query_type==null) ? 'Query' : root_schema.query_type;
    // var query_root = get_obj_of(root.definitions, query_root, 'Document');

    parse_op_for_fragment_unions(root_schema, root, op_name, query_root_name, def);

    _stdout_writer.append('typedef OP_${ op_name }_Result = {');
    handle_selection_set(op_name, def.selectionSet, [ query_root_name ]);
    _stdout_writer.append('}');

    return { op_name:op_name, variables:def.variableDefinitions };
  }

  // Init ID type as lenient abstract over String
  // TODO: optional require toIDString() for explicit string casting
  function init_base_types() {
    // ID
    _stdout_writer.append('/* - - - - Haxe / GraphQL compatibility types - - - - */');
    _stdout_writer.append('abstract IDString(String) to String from String {\n  // Relaxed safety -- allow implicit fromString');
    _stdout_writer.append('//  TODO: optional strict safety -- require explicit fromString:');
    _stdout_writer.append('//  public static inline function fromString(s:String) return cast s;');
    _stdout_writer.append('//  public static inline function ofString(s:String) return cast s;');
    _stdout_writer.append('}');
    _stdout_writer.append('typedef ID = IDString;');
    type_defined('ID');

    // Compatible with Haxe
    type_defined('String');
    type_defined('Float');
    type_defined('Int');

    // Aliases for Haxe
    _stdout_writer.append('typedef Boolean = Bool;');
    type_defined('Boolean');
    _stdout_writer.append('/* - - - - - - - - - - - - - - - - - - - - - - - - - */\n\n');
  }

}

enum ResolvedTypePath {
  ROOT;
  LEAF(str:String, optional:Bool);
  TYPE(str:String, optional:Bool, is_list:Bool);
}

class StringWriter
{
  private var _output:Array<String>;
  public function new()
  {
    _output = [];
  }
  public function is_empty() { return _output.length==0; }

  public function append(s) { _output.push(s); }

  // Remove trailing comma from last String
  public function chomp_trailing_comma() {
    _output[_output.length-1] = ~/,$/.replace(_output[_output.length-1], '');
  }

  public function toString() return _output.join("\n");

}

/*
 * GraphQL represents field types as nodes, with lists and non-nullables as
 * parent nodes. So we have a recursive structure to capture that idea:
 *
 * `type SomeList {`
 * `  items: [SomeItem!]`
 * `}`
 *
 * The type of items in AST nodes is:
 *
 *   `ListNode { NonNullNode { NamedTypeNode } }`
 *
 * TypeStringifier knows how to build a string out of this recursive structure,
 * so it gets converted to Haxe as: `Null<Array<SomeItem>>`, or if you choose
 * not to print the nulls, `Array<SomeItem>`, or as a field on a short-hand
 * typedef `?items:Array<SomeItem>` or as a field on a long-hand typedef:
 *
 *   `@:optional var items:Array<SomeItem>`
 */
@:structInit // allows assignment from anon structure with necessary fields
private class TypeStringifier
{
  public var prefix:String;
  public var suffix:String;
  public var optional:Bool;
  public var child:TSChildOrBareString;

  public function new(child:TSChildOrBareString,
                      optional=false,
                      prefix:String='',
                      suffix:String='')
  {
    this.child = child;
    this.prefix = prefix;
    this.suffix = suffix;
    this.optional = optional;
  }

  public function toString(optional_as_null=false) {
    var result = this.prefix + (switch child {
      case Left(ts): ts.toString(optional_as_null);
      case Right(str): str;
    }) + this.suffix;
    if (optional_as_null && this.optional) result = 'Null<' + result + '>';
    return result;
  }

  public function clone():TypeStringifier
  {
    var sheep = new TypeStringifier( switch this.child {
      case Left(ts): ts.clone();
      case Right(str): str;
    });
    sheep.optional = this.optional;
    sheep.prefix = this.prefix;
    sheep.suffix = this.suffix;
    return sheep;
  }

  public function follow():TypeStringifier
  {
    return switch this.child {
      case Right(str): this; // no follow necessary/possible
      case Left(ts):
      if (this.prefix=="" && this.suffix=="") {
        if (this.optional==true) {
          throw 'Do we get to this case? Can we not simply push optional to child?';
          // Push optional down to child and continue
          ts.optional = true;
          return ts.follow();
        }
        return ts.follow();
      }
      this.child = ts.follow(); // collapse children too
      return this;
    }
  }
}
typedef TSChildOrBareString = OneOf<TypeStringifier,String>;

typedef FieldArguments = Array<{
  field:String,
  arguments:Array<InputValueDefinitionNode>,
  ?variables:Array<VariableDefinitionNode>
}>

typedef OpVariables = {
  op_name:String,
  variables:Array<VariableDefinitionNode>
};


// - - - -
// Utils
// - - - -


// By @jbaudi and @fponticelli, https://gist.github.com/mrcdk/d881f85d64379e4384b1
abstract OneOf<A, B>(Either<A, B>) from Either<A, B> to Either<A, B> {
  @:from inline static function fromA<A, B>(a:A) : OneOf<A, B> return Left(a);
  @:from inline static function fromB<A, B>(b:B) : OneOf<A, B> return Right(b);

  @:to inline function toA():Null<A> return switch(this) {case Left(a): a; default: null;}
  @:to inline function toB():Null<B> return switch(this) {case Right(b): b; default: null;}

  // auto OneOf<A,B> <--> OneOf<B,A>
  @:to inline function swap():OneOf<B, A> return switch this {case Right(b): Left(b); case Left(a): Right(a);}
}


@:forward
abstract ArrayStringMap<T>(haxe.ds.StringMap<T>) from haxe.ds.StringMap<T> to haxe.ds.StringMap<T> {
  public function new() { return new haxe.ds.StringMap<T>(); }
  @:arrayAccess
  public inline function get(key:String) {
    return this.get(key);
  }
  @:arrayAccess
  public inline function arrayWrite(k:String, v:T):T {
    this.set(k, v);
    return v;
  }
}
