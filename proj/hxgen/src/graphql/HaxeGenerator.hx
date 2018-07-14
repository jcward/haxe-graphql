package graphql;

import graphql.ASTDefs;
import haxe.ds.Either;

import haxe.macro.Expr;

using Lambda;
using graphql.HaxeGenerator.GQLTypeTools;

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
typedef InterfaceType = haxe.ds.StringMap<ComplexType>;

typedef SomeNamedNode = { kind:String, name:NameNode };

@:expose
class HaxeGenerator
{
  private var _stdout_writer:StringWriter;
  private var _stderr_writer:StringWriter;
  private var _interfaces = new StringMapAA<InterfaceType>();
  private var _options:HxGenOptions;

  private var _defined_types = [];
  private var _referenced_types = [];
  private var _types_by_name = new StringMapAA<GQLTypeDefinition>();

  private var _op_type_definitions = new StringMapAA<GQLStructTypeDef>();

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
      stdout:print_to_stdout()
    };
  }

  private function get_def_name(def) return def.name.value;

  public function toString() return _stdout_writer.toString();

  private function error(s:String) _stderr_writer.append(s);

  function type_referenced(name) {
    if (_referenced_types.indexOf(name)<0) _referenced_types.push(name);
  }

  function define_type(name:String, fields:StringMapAA<GQLFieldType>=null) {
    if (_defined_types.indexOf(name)<0) {
      _defined_types.push(name);
      _types_by_name[name] = { name:name, fields:fields };
    } else {
      throw 'Cannot define type $name twice!';
    }
  }

  function parse_field_type(type:ASTDefs.TypeNode, parent:ASTDefs.TypeNode=null):GQLFieldType
  {
    var base_type:GQLFieldType = null;
    function has_kind(kind:String, type:ASTDefs.TypeNode):Bool {
      if (type==null) return false;
      if (type.kind==kind) return true;
      if (type.kind==ASTDefs.Kind.NAMED_TYPE) base_type = { name:type.name.value, is_array:false, is_optional:false };
      return has_kind(kind, type.type); // recurse
    }

    var is_array = has_kind(ASTDefs.Kind.LIST_TYPE, type);
    var non_optional = has_kind(ASTDefs.Kind.NON_NULL_TYPE, type);
    has_kind('__find_base__', type);

    if (base_type==null) throw 'Did not find a base type!';
    base_type.is_array = is_array;
    base_type.is_optional = !non_optional;

    return base_type;
  }

  /* -- TODO: REVIEW: http://facebook.github.io/graphql/October2016/#sec-Object-type-validation
                      sub-typing seems to be allowed... */
  function type0_equal_to_type1(type0:GQLFieldType, type1:GQLFieldType):Bool
  {
    // trace('STC: '+type0.toString(true)+' == '+type1.toString(true));
    return type0.name==type1.name &&
          type0.is_array==type1.is_array &&
          type0.is_optional==type1.is_optional;
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

    var interface_fields_from = new StringMapAA<String>();
    var skip_interface_fields = new StringMapAA<ComplexType>();

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

    var fields = new StringMapAA<GQLFieldType>();
    define_type(def.name.value, fields);

    for (field in def.fields) {
      // if (field.name.value=='id') debugger;
      var type = parse_field_type(field.type);
      var field_name = field.name.value;
      fields[field_name] = type; //.clone().follow();

      if (field.arguments!=null && field.arguments.length>0) {
        args.push({ field:field_name, arguments:field.arguments });
      }
/*
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
*/
    }
/*
    if (short_format) _stdout_writer.chomp_trailing_comma(); // Haxe doesn't care, but let's be tidy
    _stdout_writer.append('}');
*/

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
//    var intf = new StringMapAA<ComplexType>();
//    for (field in def.fields) {
//      var type = parse_field_type(field.type);
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
  //   define_type(def.name.value);
  //   _stdout_writer.append('enum '+def.name.value+' {');
  //   for (enum_value in def.values) {
  //     _stdout_writer.append('  '+enum_value.name.value+';');
  //   }
  //   _stdout_writer.append('}');
  // }

  function write_haxe_abstract_enum(def:ASTDefs.EnumTypeDefinitionNode) {
    // trace('Generating enum: '+def.name.value);
    define_type(def.name.value);
    _stdout_writer.append('@:enum abstract '+def.name.value+'(String) {');
    for (enum_value in def.values) {
      _stdout_writer.append('  var '+enum_value.name.value+' = "${enum_value.name.value}";');
    }
    _stdout_writer.append('}');
  }

  function write_haxe_scalar(def:ASTDefs.ScalarTypeDefinitionNode) {
    // trace('Generating scalar: '+def.name.value);
    define_type(def.name.value);
    _stdout_writer.append('/* scalar ${ def.name.value } */\nabstract ${ def.name.value }(Dynamic) { }');
  }

  function write_union_as_haxe_abstract(def:ASTDefs.UnionTypeDefinitionNode) {
    // trace('Generating union (enum): '+def.name.value);
    define_type(def.name.value);
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

  function resolve_type_path(path:Array<String>, ?op_name:String):{ last_tf:GQLFieldType, type:GQLTypeDefinition }
  {
    var ptr:GQLTypeDefinition = null;

    var err_prefix = op_name!=null ? 'Error processing operation ${ op_name }: ' : "";

    var orig_path = path.join('.');
    var last_tf = null;
    while (path.length>0) {
      var name = path.shift();
      if (ptr==null) { // at root
        ptr = _types_by_name.get(name);
        if (ptr==null) throw '${ err_prefix }Didn\'t find root type ${ name } while resolving ${ orig_path }';
      } else {
        if (ptr.fields==null) throw '${ err_prefix }Expecting type ${ ptr.name } to have fields --> ${ name }!';
        last_tf = ptr.fields.get(name);
        if (last_tf==null) throw '${ err_prefix }Expecting type ${ ptr.name } to have field ${ name }!';

        // GraphQL query type paths don't care about array / optional
        ptr = _types_by_name.get(last_tf.name);
        if (ptr==null) throw '${ err_prefix }Didn\'t find expected root type ${ last_tf.name }';
      }
    }

    return { last_tf:last_tf, type:ptr };

    // trace('Looking for ${ orig_path }, last_tf was ${ last_tf }');
    // return last_tf;
    /*
    var is_list = last_tf.is_array();
    var is_opt = last_tf.is_optional();
    var type_string:String = is_list ? array_inner_type(last_tf) : last_tf.toString();

    var resolved = _types_by_name[type_string];
    if (resolved==null) throw '${ err_prefix }Resolved ${ orig_path } to unknown type ${ type_string }';
    if (resolved.fields==null) {
      return LEAF(type_string, is_opt, is_list);
    } else {
      return TYPE(type_string, is_opt, is_list);
    }
    */
  }

  function parse_op_for_fragment_unions(root_schema:SchemaMap,
                                        root:ASTDefs.DocumentNode,
                                        op_name:String,
                                        op_root_type:String,
                                        def:ASTDefs.OperationDefinitionNode):Void
  {
    // _stdout_writer.append('typedef OP_${ op_name }_Result = {');
    // handle_selection_set(op_name, def.selectionSet, [ op_root_type ], true);
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

    _stdout_writer.append('/* union for operation $op_name fragments at ${ type_path.join(".") } */');
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

  function generate_type_based_on_selection_set(type_name:String,
                                                op_name:String,
                                                sel_set:{ selections:Array<SelectionNode> },
                                                type_path:Array<String>, // always abs
                                                is_gen_fragments:Bool=false):GQLStructTypeDef
  {
    if (sel_set==null || sel_set.selections==null) {
      // Nothing left to do...
    }

    inline function init_struct_fields() return new StringMapAA< OneOf< GQLFieldType, GQLStructTypeDef > >();

    // No output for is_gen_fragments
    var fields = init_struct_fields();
    var struct_type = { name:type_name, fields:fields };

    // Store in output list ?? Always? Sub types?
    _op_type_definitions[type_name] = struct_type;

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
        var resolved = resolve_type_path(next_type_path, op_name);

        if (resolved.type.fields==null) { // Leaf type, e.g. String, Int, a scalar, etc
          if (field_node.selectionSet!=null) throw 'Cannot specify sub-fields of ${ resolved.type.name } in ${ type_path.join(",") } of operation ${ op_name }';
          var nt:GQLFieldType = resolved.last_tf;
          fields[alias] = nt;
        } else {
          if (field_node.selectionSet==null) throw 'Must specify sub-fields of ${ resolved.type.name } in ${ type_path.join(",") } of operation ${ op_name }';
          var sub_type_name = type_name+'_'+resolved.type.name;
          var sub_type:GQLStructTypeDef = generate_type_based_on_selection_set(op_name, sub_type_name, field_node.selectionSet, [ resolved.type.name ], is_gen_fragments);
          /*if (sub_type.has_union_field()) {
            
          } else { // merge into my type */
            fields[alias] = sub_type;
       /* } */
        }
      }
    }

    return struct_type;
  }

  function write_operation_def_result(root_schema:SchemaMap,
                                      root:ASTDefs.DocumentNode,
                                      def:ASTDefs.OperationDefinitionNode):OpVariables
  {
    if (def.name==null || def.name.value==null) throw 'Only named operations are supported...';

    var op_name = def.name.value;

    _stdout_writer.append('/* Operation def: ${ op_name } */');

    var op_root_type = '';
    if (def.operation=='query') {
      op_root_type = (root_schema==null || root_schema.query_type==null) ? 'Query' : root_schema.query_type;
    } else if (def.operation=='mutation') {
      op_root_type = (root_schema==null || root_schema.mutation_type==null) ? 'Mutation' : root_schema.mutation_type;
    } else {
      throw 'Error processing ${ op_name }: Only query and mutation are supported.';
    }

    parse_op_for_fragment_unions(root_schema, root, op_name, op_root_type, def);

    // gen type based on selection set
    generate_type_based_on_selection_set('OP_${ op_name }_Result',
                                         op_name,
                                         def.selectionSet,
                                         [ op_root_type ]);

    /*
    _stdout_writer.append('typedef OP_${ op_name }_Result = {');
    handle_selection_set(op_name, def.selectionSet, [ op_root_type ]);
    _stdout_writer.append('}');
    */

    return { op_name:op_name, variables:def.variableDefinitions };
  }

  function print_to_stdout():String {
    var stdout_writer = new StringWriter();
    stdout_writer.append('/* - - - - Haxe / GraphQL compatibility types - - - - */');
    stdout_writer.append('abstract IDString(String) to String from String {\n  // Relaxed safety -- allow implicit fromString');
    stdout_writer.append('//  TODO: optional strict safety -- require explicit fromString:');
    stdout_writer.append('//  public static inline function fromString(s:String) return cast s;');
    stdout_writer.append('//  public static inline function ofString(s:String) return cast s;');
    stdout_writer.append('}');
    stdout_writer.append('typedef ID = IDString;');
    stdout_writer.append('');
    stdout_writer.append('');
    
    // Print types
    for (name in _types_by_name.keys()) {
      var type = _types_by_name[name];
      stdout_writer.append( GQLTypeTools.type_to_string(type) );
      stdout_writer.append('');
      stdout_writer.append('');
    }

    // Print operation struct types
    for (name in _op_type_definitions.keys()) {
      var type = _op_type_definitions[name];
      stdout_writer.append( GQLTypeTools.type_to_string(type) );
      stdout_writer.append('');
      stdout_writer.append('');
    }

    stdout_writer.append('\n\n/* - - - - - - - - - - - - - - - - - - - - - - - - - */\n\n');

    return stdout_writer.toString();
  }

  // Init ID type as lenient abstract over String
  // TODO: optional require toIDString() for explicit string casting
  function init_base_types() {
    // ID
    define_type('ID'); // see generated IDString above

    // Compatible with Haxe
    define_type('String');
    define_type('Float');
    define_type('Int');
    define_type('Bool');
  }

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

  public function toString():String return _output.join("\n");
}

// These will map to ComplexTypes:
//  String        --> TPath(anme)                    if not array, not optional
//  Array<String> --> TPath('Array', [TPath(name)])  if not array, not optional
//  ?...          --> TOptional(...)                 if optional
typedef GQLFieldType = {
  name:String, // aka, like a TPath(TypePath), but no pack
  is_array:Bool,
  is_optional:Bool
}

// Will map to Haxe TypeDefinition (fields of FVar(t:ComplexType as above))
typedef GQLTypeDefinition = { name:String, ?fields:StringMapAA<GQLFieldType> }

// Will map to TAnonymous with nested structure definitions
typedef GQLStructTypeDef = { name:String, ?fields:StringMapAA<OneOf< GQLFieldType, GQLStructTypeDef>> }

class GQLTypeTools
{
  /*public static function toString(ct:ComplexType, opt_as_meta:Bool):String
  {
    var p = new haxe.macro.Printer();
    // TODO: opt_as_meta
    return p.printComplexType(ct);
  }*/
  public static function to_haxe_field(field_name:String, gql_f:OneOf<GQLFieldType, GQLStructTypeDef>):Field
  {
    return switch gql_f {
      case Left(td):
        var ct:ComplexType = TPath({ pack:[], name:td.name });
        if (td.is_array) ct = TPath({ pack:[], name:'Array', params:[ TPType(ct) ] });
        var field = { name:field_name, kind:FVar(ct, null), meta:[], pos:FAKE_POS };
        if (td.is_optional) field.meta.push({ name:":optional", pos:FAKE_POS });
        field;
      case Right(gql_struct_td):
        var fields = [];
        var ct:ComplexType = TAnonymous(fields);
        for (fname in gql_struct_td.fields.keys()) {
          var inner = gql_struct_td.fields[fname];
          fields.push(to_haxe_field(fname, inner));
        }
        var field = { name:field_name, kind:FVar(ct, null), meta:[], pos:FAKE_POS };
        field;
      
    }
  }

  public static function type_to_string(td:OneOf<GQLTypeDefinition, GQLStructTypeDef>):String {
    var p = new CustomPrinter("  ", true);
    switch td {

      case Left(gql_td): // GQL types
        if (gql_td.fields==null) return '/* Basic type ${ gql_td.name }*/';
        var haxe_td:TypeDefinition = {
          pack:[], name:gql_td.name, pos:FAKE_POS, kind:TDStructure, fields:[]
        };
        for (field_name in gql_td.fields.keys()) {
          haxe_td.fields.push( to_haxe_field(field_name, gql_td.fields[field_name]) );
        }
        return p.printTypeDefinition( haxe_td );

      case Right(gql_struct_td): // GQL query / struct types
        var haxe_td:TypeDefinition = {
          pack:[], name:gql_struct_td.name, pos:FAKE_POS, kind:TDStructure, fields:[]
        };
        for (field_name in gql_struct_td.fields.keys()) {
          haxe_td.fields.push( to_haxe_field(field_name, gql_struct_td.fields[field_name]) );
        }
        return p.printTypeDefinition( haxe_td );

      return 'what';
    }
  }

  private static var FAKE_POS = { min:0, max:0, file:'Untitled' };

}

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


// StringMap with Array Access
@:forward
abstract StringMapAA<T>(haxe.ds.StringMap<T>) from haxe.ds.StringMap<T> to haxe.ds.StringMap<T> {
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
