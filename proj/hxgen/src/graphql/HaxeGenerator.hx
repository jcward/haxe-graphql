package graphql;

import graphql.ASTDefs;
import haxe.ds.Either;

import haxe.macro.Expr;

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
typedef InterfaceType = haxe.ds.StringMap<ComplexType>;

typedef SomeNamedNode = { kind:String, name:NameNode };

@:expose
class HaxeGenerator
{
  private var _stderr_writer:StringWriter;
  private var _interfaces = new StringMapAA<InterfaceType>();
  private var _options:HxGenOptions;

  private var _defined_types = [];
  private var _referenced_types = [];
  private var _types_by_name = new StringMapAA<GQLTypeDefinition>();

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
      case ASTDefs.Kind.ENUM_TYPE_DEFINITION:
        write_haxe_abstract_enum(cast def);
      case ASTDefs.Kind.OBJECT_TYPE_DEFINITION:
        var args = write_haxe_typedef(cast def);
        handle_args([get_def_name(cast def)], args);
      case ASTDefs.Kind.UNION_TYPE_DEFINITION:
        write_union_as_haxe_abstract(cast def);
      case ASTDefs.Kind.OPERATION_DEFINITION:
        // No-op, still generating type definitions
      case ASTDefs.Kind.INTERFACE_TYPE_DEFINITION:
        // TODO: anything special about Interfaces ?
        var args = write_haxe_typedef(cast def);
        handle_args([get_def_name(cast def)], args);
      case ASTDefs.Kind.INPUT_OBJECT_TYPE_DEFINITION:
        // TODO: anything special about InputObjectTypeDefinition ?
        var args = write_haxe_typedef(cast def);
        handle_args([get_def_name(cast def)], args);
      case ASTDefs.Kind.FRAGMENT_DEFINITION:
        // No-op, still generating type definitions
      default:
        var name = (cast def).name!=null ? (' - '+(cast def).name.value) : '';
        error('Error: unknown / unsupported definition kind: '+def.kind+name);
      }
    }
    // Third pass: genearte fragment definitions
    for (def in doc.definitions) switch def.kind {
      case ASTDefs.Kind.FRAGMENT_DEFINITION:
        write_fragment_as_haxe_typedef(cast def);
      default:
    }

    // Fourth pass: write operation results
    for (def in doc.definitions) switch def.kind {
      case ASTDefs.Kind.OPERATION_DEFINITION:
        var vars = write_operation_def_result(root_schema, doc, cast def);
        handle_variables(vars);
      default:
    }

    // Ensure all referenced types are defined
    for (t in _referenced_types) {
      if (_defined_types.indexOf(t)<0) {
        error('Error: unknown type: '+t);
      }
    }
    return {
      stderr:_stderr_writer.toString(),
      stdout:print_to_stdout()
    };
  }

  private function get_def_name(def) return def.name.value;

  private function error(s:String) _stderr_writer.append(s);

  function type_referenced(name) {
    if (_referenced_types.indexOf(name)<0) _referenced_types.push(name);
  }

  function define_type(t:GQLTypeDefinition) {
    var name = switch t {
      case TBasic(name) | TEnum(name, _) | TScalar(name) | TUnion(name, _) | TStruct(name, _): name;
    }
    if (_defined_types.indexOf(name)<0) {
      _defined_types.push(name);
      _types_by_name[name] = t;
    } else {
      throw 'Cannot define type $name twice!';
    }
  }

  function parse_field_type(type:ASTDefs.TypeNode, parent:ASTDefs.TypeNode=null):GQLFieldType
  {
    var field_type:GQLFieldType = { type:null, is_array:false, is_optional:false };

    function has_kind(kind:String, type:ASTDefs.TypeNode):Bool {
      if (type==null) return false;
      if (type.kind==kind) return true;
      if (type.kind==ASTDefs.Kind.NAMED_TYPE) {
        field_type.type = TPath(type.name.value);
        type_referenced(type.name.value);
      }
      return has_kind(kind, type.type); // recurse
    }

    field_type.is_array = has_kind(ASTDefs.Kind.LIST_TYPE, type);
    field_type.is_optional = type.kind!=ASTDefs.Kind.NON_NULL_TYPE;
    has_kind(' find base ', type);

    if (field_type.type==null) throw 'Did not find the base type!';
    return field_type;
  }

  /* -- TODO: REVIEW: http://facebook.github.io/graphql/October2016/#sec-Object-type-validation
                      sub-typing seems to be allowed... */
  function field_types_equivalent(field_type_0:GQLFieldType, field_type_1:GQLFieldType):Bool
  {
    return field_type_0.is_array==field_type_1.is_array &&
           field_type_0.is_optional==field_type_1.is_optional &&
           field_type_0.type==field_type_1.type;
  }

  function write_fragment_as_haxe_typedef(def:ASTDefs.FragmentDefinitionNode)
  {
    var on_type = def.typeCondition.name.value;
    var tname = 'Fragment_${ def.name.value }';
    // If fragments can have fragments, this could
    generate_type_based_on_selection_set(tname,
                                         tname,
                                         def.selectionSet,
                                         on_type);
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
//            if (!field_types_equivalent(intf.get(field_name), skip_interface_fields[field_name])) {
//              throw 'Type '+def.name.value+' inherits field '+field_name+' from multiple interfaces ('+ifname+', '+interface_fields_from[field_name]+'), the types of which do not match.';
//            }
//          }
//        }
//      }
//    }

    var fields = new StringMapAA<GQLFieldType>();
    define_type(TStruct(def.name.value, fields));

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
        if (!field_types_equivalent(type, skip_interface_fields.get(field_name))) {
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
    var values = [];
    define_type(TEnum(def.name.value, values));
    for (enum_value in def.values) {
      values.push(enum_value.name.value);
    }
  }

  function write_haxe_scalar(def:ASTDefs.ScalarTypeDefinitionNode) {
    // trace('Generating scalar: '+def.name.value);
    define_type(TScalar(def.name.value));
    //_stdout_writer.append('/* scalar ${ def.name.value } */\nabstract ${ def.name.value }(Dynamic) { }');
  }

  function write_union_as_haxe_abstract(def:ASTDefs.UnionTypeDefinitionNode) {
    var values = [];
    for (type in def.types) {
      if (type.name==null) throw 'Expecting Named Type';
      values.push(type.name.value);
    }

    generate_union_of_types(values, def.name.value);
  }

  // values and return are all TPath Strings
  function generate_union_of_types(values:Array<String>, tname:String=null):String
  {
    if (tname==null) {
      values.sort(function(a,b) return a>b ? 1 : -1);
      tname = 'U__'+values.join('_');
      if (_defined_types.indexOf(tname)>=0) return tname;
    }
    define_type(TUnion(tname, values));
    return tname;
  }

  // A schema definition is just a mapping / typedef alias to specific types
  function write_schema_def(def:ASTDefs.SchemaDefinitionNode):SchemaMap {
    var rtn = { query_type:null, mutation_type:null };

    //_stdout_writer.append('/* Schema: */');
    for (ot in def.operationTypes) {
      var op = Std.string(ot.operation);
      switch op {
        case "query" | "mutation": //  | "subscription": is "non-spec experiment"
        var capitalized = op.substr(0,1).toUpperCase() + op.substr(1);
        //_stdout_writer.append('typedef Schema${ capitalized }Type = ${ ot.type.name.value };');
        if (op=="query") rtn.query_type = ot.type.name.value;
        if (op=="mutation") rtn.mutation_type = ot.type.name.value;
        default: throw 'Unexpected schema operation: ${ op }';
      }
    }

    return rtn;
  }

  function resolve_type(t:GQLTypeRef):GQLTypeDefinition return switch (t) {
    case TPath(name):_types_by_name.get(name);
    case TAnon(def): def;
  }

  function resolve_field(path:Array<String>, ?op_name:String):GQLFieldType
  {
    var ptr:GQLTypeDefinition = null;

    var err_prefix = op_name!=null ? 'Error processing operation ${ op_name }: ' : "";

    var orig_path = path.join('.');
    while (path.length>0) {
      var name = path.shift();
      if (ptr==null) { // select from root types
        ptr = _types_by_name.get(name);
        if (ptr==null) throw '${ err_prefix }Didn\'t find root type ${ name } while resolving ${ orig_path }';
        if (path.length==0) return { is_array:false, is_optional:false, type:TPath(name) };
      } else {
        switch ptr {
          case TBasic(tname) | TScalar(tname) | TEnum(tname, _):
            throw '${ err_prefix }Expecting type ${ tname } to have field ${ name }!';
          case TStruct(tname, fields):
            var field = fields[name];
            if (field==null) throw '${ err_prefix }Expecting type ${ tname } to have field ${ name }!';
            if (path.length==0) return field;
            ptr = resolve_type(field.type);
            if (ptr==null) throw '${ err_prefix }Did not find type ${ field.type } referenced by ${ tname }.${ name }!';
          case TUnion(tname, _):
            throw 'TODO: deterimne if graphql lets you poke down into common fields of unions...';
        }
      }
    }

    throw '${ err_prefix }couldn\'t resolve path: ${ orig_path }';

    // trace('Looking for ${ orig_path }, last_field was ${ last_field }');
    // return last_field;
    /*
    var is_list = last_field.is_array();
    var is_opt = last_field.is_optional();
    var type_string:String = is_list ? array_inner_type(last_field) : last_field.toString();

    var resolved = _types_by_name[type_string];
    if (resolved==null) throw '${ err_prefix }Resolved ${ orig_path } to unknown type ${ type_string }';
    if (resolved.fields==null) {
      return LEAF(type_string, is_opt, is_list);
    } else {
      return TYPE(type_string, is_opt, is_list);
    }
    */
  }

  private var _inline_fragment_signatures = new Array<String>();
  function get_fragment_tname(sel_node:Dynamic)
  {
    // It's either the name of a NamedFragment... or for inline,
    // generate e.g. PersonFRAG1 (depending on which fields we pick
    // from the concrete type)
    if (sel_node.kind==Kind.FRAGMENT_SPREAD) {
      return 'Fragment_'+sel_node.name.value;
    }

    var concrete = sel_node.typeCondition.name.value;

    function define_frag(key:String) {
      var idx = _inline_fragment_signatures.length;
      _inline_fragment_signatures.push(key);
      var tname = 'InlineFrag${idx}_on_${concrete}';
      generate_type_based_on_selection_set(tname,
                                           tname,
                                           sel_node.selectionSet,
                                           concrete);
      return idx;
    }

    var is_simple = true;
    var fields = [ for (subsel in ((sel_node.selectionSet.selections):Array<Dynamic>)) {
      (subsel.kind!='Field') ? { is_simple = false; null; } : subsel.name.value;
    }];
    var idx = -1;
    var prefix = 'InlineFragment|${concrete}|';
    if (is_simple) {
      fields.sort(function(a,b) return a>b ? 1 : -1);
      var key = prefix+fields.join('|');
      idx = _inline_fragment_signatures.indexOf(key);
      if (idx<0) {
        idx = define_frag(key);
      }
    } else {
      idx = define_frag(null);
    }
    return 'InlineFrag${idx}_on_${concrete}';
  }

  function generate_type_based_on_selection_set(type_name:String,
                                                op_name:String,
                                                sel_set:{ selections:Array<SelectionNode> },
                                                base_type:String,
                                                depth:Int=0):GQLTypeDefinition
  {
    var fields = new StringMapAA<GQLFieldType>();

    // Determine possible types, based on fragments. If multiple types,
    // then we generate a union.
    var possible_types = [ base_type ];
    for (sel_node in sel_set.selections) {
      if ((cast sel_node).typeCondition!=null) {
        var possible = get_fragment_tname(cast sel_node);
        if (possible_types.indexOf(possible)<0) possible_types.push(possible);
      }
    }

    var type_path = [ base_type ];

    for (sel_node in sel_set.selections) {
      switch (sel_node.kind) { // FragmentSpread | Field | InlineFragment
      case Kind.FIELD:
        var field_node:FieldNode = cast sel_node;

        var name:String = field_node.name.value;
        var alias:String = field_node.alias==null ? name : field_node.alias.value;

        var next_type_path = type_path.slice(0);
        next_type_path.push(name);
        var resolved = resolve_field(next_type_path, op_name);
        var type = resolve_type(resolved.type);

        switch type {
          case TBasic(tname) | TScalar(tname) | TEnum(tname, _):
            if (field_node.selectionSet!=null) throw 'Cannot specify sub-fields of ${ tname } in ${ type_path.join(".") } of operation ${ op_name }';
            fields[alias] = resolved;
          case TStruct(tname, tfields):
            if (field_node.selectionSet==null) throw 'Must specify sub-fields of ${ tname } in ${ type_path.join(".") } of operation ${ op_name }';

            var sub_type_name = (depth==0 && StringTools.endsWith(type_name, '_Result')) ?
              StringTools.replace(type_name, '_Result', '_InnerResult') : type_name+'__'+name;

            var sub_type = generate_type_based_on_selection_set(sub_type_name, op_name, field_node.selectionSet, tname, depth+1);
            var f = { type:null, is_array:resolved.is_array, is_optional:resolved.is_optional };
            fields[alias] = f;
            /*if (sub_type.has_union_field()) {
            } else */if (depth==0) { // Make separate, named type for first-level of query
              f.type = TPath(sub_type_name);
            } else { // merge into my type
              _types_by_name.remove(sub_type_name);
              _defined_types.remove(sub_type_name);
              f.type = TAnon(sub_type);
            }
          case TUnion(tname, _):
            if (field_node.selectionSet!=null) throw 'Hmm, do we allow specifying sub-fields of union ${ tname } in ${ type_path.join(".") } of operation ${ op_name }';
            fields[alias] = resolved;
        }
        case Kind.INLINE_FRAGMENT:
          // Handled above
        case Kind.FRAGMENT_SPREAD:
          // Handled above
        default: throw 'Unhandled sel_node kind ${ sel_node.kind }';
      }
    }

    if (possible_types.length>1) {
      generate_union_of_types(possible_types, type_name);
      return _types_by_name[type_name];
    } else {
      define_type(TStruct(type_name, fields));
      return _types_by_name[type_name];
    }
    
  }

  function write_operation_def_result(root_schema:SchemaMap,
                                      root:ASTDefs.DocumentNode,
                                      def:ASTDefs.OperationDefinitionNode):OpVariables
  {
    if (def.name==null || def.name.value==null) throw 'Only named operations are supported...';

    var op_name = def.name.value;

    //_stdout_writer.append('/* Operation def: ${ op_name } */');

    var op_root_type = '';
    if (def.operation=='query') {
      op_root_type = (root_schema==null || root_schema.query_type==null) ? 'Query' : root_schema.query_type;
    } else if (def.operation=='mutation') {
      op_root_type = (root_schema==null || root_schema.mutation_type==null) ? 'Mutation' : root_schema.mutation_type;
    } else {
      throw 'Error processing ${ op_name }: Only query and mutation are supported.';
    }

    // gen type based on selection set
    generate_type_based_on_selection_set('OP_${ op_name }_Result',
                                         op_name,
                                         def.selectionSet,
                                         op_root_type);

    return { op_name:op_name, variables:def.variableDefinitions };
  }

  function print_to_stdout():String {
    var stdout_writer = new StringWriter();
    stdout_writer.append('/* - - - - Haxe / GraphQL compatibility types - - - - */');
    stdout_writer.append('abstract ID(String) to String from String {\n  // Relaxed safety -- allow implicit fromString');
    stdout_writer.append('  //  TODO: optional strict safety -- require explicit fromString:');
    stdout_writer.append('  //  public static inline function fromString(s:String) return cast s;');
    stdout_writer.append('  //  public static inline function ofString(s:String) return cast s;');
    stdout_writer.append('}');
    stdout_writer.append('');

    // Check for collisions (Bool is the only problematic identifier?)
    if (_types_by_name.exists('Bool')) GQLTypeTools.bool_collision = true;

    // Print types
    for (name in _types_by_name.keys()) {
      if (_basic_types.indexOf(name)>=0) continue;
      var type = _types_by_name[name];
      stdout_writer.append( GQLTypeTools.type_to_string(type) );
      stdout_writer.append('');
    }

    stdout_writer.append('\n\n/* - - - - - - - - - - - - - - - - - - - - - - - - - */\n\n');

    return stdout_writer.toString();
  }

  // Init ID type as lenient abstract over String
  // TODO: optional require toIDString() for explicit string casting
  private static var _basic_types = ['ID', 'String', 'Float', 'Int', 'Boolean'];
  function init_base_types() {
    // ID
    for (t in _basic_types) define_type(TBasic(t));
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
//  String        --> TPath(name)                    if not array, not optional
//  Array<String> --> TPath('Array', [TPath(name)])  if array
//  optional adds metadata to field
enum GQLTypeRef {
  TPath(name:String);
  TAnon(type:GQLTypeDefinition);
}
typedef GQLFieldType = {
  type:GQLTypeRef, // aka, like a TPath(TypePath), or anon definition
  is_array:Bool,
  is_optional:Bool
}

enum GQLTypeDefinition {
  TBasic(name:String);
  TScalar(name:String);
  TEnum(name:String, values:Array<String>);
  TUnion(name:String, type_paths:Array<String>);
  TStruct(name:String, fields:StringMapAA<GQLFieldType>);
}

// Will map to Haxe TypeDefinition (fields of FVar(t:ComplexType as above))
// typedef GQLTypeDefinition = { name:String, type:GQLTypeIdentifier }

// Will map to TAnonymous with nested structure definitions
// typedef GQLStructTypeDef = { name:String, ?fields:StringMapAA<OneOf< GQLFieldType, GQLStructTypeDef>> }

class GQLTypeTools
{
  /*public static function toString(ct:ComplexType, opt_as_meta:Bool):String
  {
    var p = new haxe.macro.Printer();
    // TODO: opt_as_meta
    return p.printComplexType(ct);
  }*/

  public static var bool_collision = false;
  public static function gql_to_haxe_type_name_transforms(tname:String):String
  {
    if (tname=="Bool" && bool_collision) return "Bool_";
    if (tname=="Boolean") return "Bool";
    return tname;
  }

  public static function to_haxe_field(field_name:String, gql_f:GQLFieldType):Field
  {
    switch gql_f.type {
      case TPath(name):
        var ct:ComplexType = TPath({ pack:[], name:gql_to_haxe_type_name_transforms(name) });
        if (gql_f.is_array) ct = TPath({ pack:[], name:'Array', params:[ TPType(ct) ] });
        var field = { name:field_name, kind:FVar(ct, null), meta:[], pos:FAKE_POS };
        if (gql_f.is_optional) field.meta.push({ name:":optional", pos:FAKE_POS });
        return field;

      case TAnon(TStruct(name, inner_fields)):
        var fields:Array<haxe.macro.Field> = [];
        for (fname in inner_fields.keys()) {
          var inner = inner_fields[fname];
          fields.push(to_haxe_field(fname, inner));
        }
        var field = { name:field_name, kind:FVar(TAnonymous(fields), null), meta:[], pos:FAKE_POS };
        if (gql_f.is_optional) field.meta.push({ name:":optional", pos:FAKE_POS });
        return field;

      case TAnon(any): throw 'Non-struct types are not supported in TAnon: ${ any }';
      //default: throw 'Basic types are not supported in TAnon';
    }
  }

  public static function type_to_string(td:GQLTypeDefinition):String {
    var p = new CustomPrinter("  ", true);
    switch td {
      case TBasic(tname): return '';
      case TScalar(tname):
        return '/* Scalar type ${ tname } */\nabstract ${ tname }(Dynamic) { }';
      case TEnum(tname, values):
        return '/* Enum type ${ tname } */\n@:enum abstract ${ tname }(String) {\n  ' +
          values.map(function(v) return 'var $v = "$v";').join("\n  ")+'\n}';
      case TStruct(name, fields):
        var haxe_td:TypeDefinition = {
          pack:[], name:gql_to_haxe_type_name_transforms(name), pos:FAKE_POS, kind:TDStructure, fields:[]
        };
        for (field_name in fields.keys()) {
          haxe_td.fields.push( to_haxe_field(field_name, fields[field_name]) );
        }
        return p.printTypeDefinition( haxe_td );
      case TUnion(tname, type_paths):
        var writer = new StringWriter();
        var union_types_note = type_paths.map(function(t) return t).join(" | ");
        writer.append('/* union '+tname+' = ${ union_types_note } */');
        writer.append('abstract '+tname+'(Dynamic) {');
        for (type_name in type_paths) {
          writer.append(' @:from static function from${ type_name }(v:${ type_name }) return cast v;');
        }
        writer.append('}');
        return writer.toString();
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
