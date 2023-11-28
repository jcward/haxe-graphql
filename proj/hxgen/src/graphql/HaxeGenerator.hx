package graphql;

import graphql.ASTDefs;

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

typedef SomeNamedNode = { kind:String, name:NameNode };

#if COVERAGE
@:build(coverme.Instrument.build())
#end
@:expose
class HaxeGenerator
{
  private static var OP_PREFIX = 'OP_';
  private static var OP_OUTER_SUFFIX = '_Result';
  private static var OP_INNER_SUFFIX = '_InnerResult';
  private static var OP_VARS_SUFFIX = '_Vars';
  private static var FRAGMENT_PREFIX = 'Fragment_';
  public #if !COVERAGE inline #end static var UNION_SELECTION_SEPARATOR = '_ON_';
  private static var ARGS_PREFIX = 'Args_';
  private static var GENERATED_UNION_PREFIX = 'U_';

  /* https://github.com/nadako/coverme/issues/1 - issues with inline */
  public #if !COVERAGE inline #end static var DEFAULT_SEPARATOR = '__';

  private var _stderr_writer:StringWriter;
  private var _options:HxGenOptions;

  private var _fragment_defs = new Array<ASTDefs.FragmentDefinitionNode>();
  private var _defined_types = [];
  private var _list_of_interfaces = [];
  private var _map_of_union_types = new StringMapAA<Array<String>>();
  private var _referenced_types = [];
  private var _types_by_name = new StringMapAA<GQLTypeDefinition>();
  private var _interfaces_implemented = new StringMapAA<Array<String>>();

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
      // Don't let this crash, catch errors, and write log
      try {
        result = gen.parse_document(doc);
      } catch (e:Dynamic) {
        // e can be ignored for end users -- determined errors are logged to stderr,
        // and unexpected errors (e.g. null object reference) are not helpful to end users.
        var known_errors:String = gen.get_stderr();
        // if there are no known errors, output the exception.
        if (known_errors.length==0) known_errors = '${ e }';
        result = {
          stdout:'',
          stderr:known_errors+'\nHaxeGenerator failed!'
        }
      }
    }

    if (throw_on_error && result.stderr.length>0) {
      throw result.stderr;
    }

    return result;
  }

  public function get_stderr():String return _stderr_writer.toString();

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
      var args_name = '${ ARGS_PREFIX }${ type_path.join(DEFAULT_SEPARATOR) }${ DEFAULT_SEPARATOR }${ a.field }';
      var args_obj:ObjectTypeDefinitionNode = {
        kind:Kind.OBJECT_TYPE_DEFINITION,
        name:{ value:args_name, kind:Kind.NAME },
        fields:cast a.arguments
      };
      ingest_tstruct_like_type(args_obj);
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
      name:{ value:'${ OP_PREFIX }${ opv.op_name }${ OP_VARS_SUFFIX }', kind:Kind.NAME },
      fields:fields
    };
    ingest_tstruct_like_type(vars_obj);
  }

  // Parse a graphQL AST document, generating Haxe code
  private function parse_document(doc:DocumentNode) {
    // Parse definitions
    init_base_types();

    var root_schema:SchemaMap = null;

    // First pass: parse the schema def and gather type extensions
    for (def in doc.definitions) {
      switch (def.kind) {
        case ASTDefs.Kind.SCHEMA_DEFINITION:
          if (root_schema!=null) error('Error: cannot specify two schema definitions');
          root_schema = ingest_schema_def(cast def);
        case ASTDefs.Kind.OBJECT_TYPE_EXTENSION:
          apply_type_extension(cast def, doc.definitions);
        case _:
      }
    }

    // Second pass: parse everything else
    for (def in doc.definitions) {
      switch (def.kind) {
      case ASTDefs.Kind.SCHEMA_DEFINITION:
        // null op, handled above
      case ASTDefs.Kind.SCALAR_TYPE_DEFINITION:
        ingest_scalar_type_def(cast def);
      case ASTDefs.Kind.ENUM_TYPE_DEFINITION:
        ingest_enum_type_def(cast def);
      case ASTDefs.Kind.OBJECT_TYPE_DEFINITION:
        var args = ingest_tstruct_like_type(cast def);
        handle_args([get_def_name(cast def)], args);
      case ASTDefs.Kind.UNION_TYPE_DEFINITION:
        ingest_union_type_def(cast def);
      case ASTDefs.Kind.OPERATION_DEFINITION:
        // No-op, still generating type definitions
      case ASTDefs.Kind.INTERFACE_TYPE_DEFINITION:
        // TODO: anything special about Interfaces ?
        _list_of_interfaces.push((cast def).name.value);
        var args = ingest_tstruct_like_type(cast def);
        handle_args([get_def_name(cast def)], args);
      case ASTDefs.Kind.INPUT_OBJECT_TYPE_DEFINITION:
        // TODO: anything special about InputObjectTypeDefinition ?
        var args = ingest_tstruct_like_type(cast def);
        handle_args([get_def_name(cast def)], args);
      case ASTDefs.Kind.FRAGMENT_DEFINITION:
        // No-op, still generating type definitions
        _fragment_defs.push(cast def);
      case ASTDefs.Kind.OBJECT_TYPE_EXTENSION:
        // Handled above
      default:
        var name = (cast def).name!=null ? (' - '+(cast def).name.value) : '';
        error('Error: unknown / unsupported definition kind: '+def.kind+name);
      }
    }

    // Ensure all referenced types are defined
    for (t in _referenced_types) {
      if (_defined_types.indexOf(t)<0) {
        error('Error: unknown type: '+t);
      }
    }

    // Third pass: generate fragment definitions
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

    // Ensure all interface implementations are valid, including
    // type checking (with covariance)
    ensure_interface_implementations();

    return {
      stderr:_stderr_writer.toString(),
      stdout:print_to_stdout()
    };
  }

  private function get_node_named(find_name:String,
                                  nodes:Array<SomeNamedNode>,
                                  ignore:Dynamic->Bool=null):Dynamic
  {
    if (nodes==null || nodes.length==0) return null;
    for (node in nodes) {
      if (node.name.value==find_name) {
        if (ignore!=null && !ignore(node)) return node;
      }
    }
    return null;
  }

  private function apply_type_extension(ext:ObjectTypeDefinitionNode,
                                        definitions:Array<DefinitionNode>)
  {
    // Do not modify the definitions array itself, but you can modify the items in it

    var base:Dynamic = get_node_named(ext.name.value, cast definitions, function(node) {
      return node!=null && node.kind==ASTDefs.Kind.OBJECT_TYPE_EXTENSION;
    });
    if (base==null) {
      error('Type extension for ${ ext.name.value } didn\'t find base type!');
      return;
    }

    // Push extensions into root type
    for (items_name in ['fields', 'directives', 'interfaces']) {
      var ext_items:Array<SomeNamedNode> = Reflect.field(ext, items_name);
      if (ext_items!=null && ext_items.length>0) {
        var base_items = Reflect.field(base, items_name);
        if (base_items==null) {
          base_items = [];
          Reflect.setField(base, items_name, base_items);
        }
        for (val in ext_items) {
          var existing = get_node_named(val.name.value, base_items);
          if (existing!=null) {
            error('Type extension for ${ ext.name.value } cannot redefine ${ items_name }.${ val.name.value }');
          } else {
            base_items.push(val);
          }
        }
      }
    }
  }

  private function ensure_interface_implementations()
  {
    for (tname in _types_by_name.keys()) {
      if (is_object_type(tname) && _interfaces_implemented.exists(tname)) {
        for (iname in _interfaces_implemented[tname]) {
          //trace('$tname implements $iname');
          var tfields = switch _types_by_name[tname] {
            case TStruct(name, fields): fields;
            default: error('Object type $tname expected to have fields!', true); null;
          }
          var ifields = switch _types_by_name[iname] {
            case TStruct(name, fields): fields;
            default: error('Interface $iname expected to have fields!', true); null;
          }
          for (field_name in ifields.keys()) {
            var ifield = ifields[field_name];
            var tfield = tfields[field_name];
            if (tfield==null) {
              error('Type $tname implements $iname, but doesn\'t provide field $field_name');
              continue;
            }
            if (ifield.is_array != tfield.is_array) {
              error('Type $tname implements $iname, but the type of field $field_name doesn\'t match (List vs non-List)');
              continue;
            }
            if (ifield.is_optional != tfield.is_optional) {
              error('Type $tname implements $iname, but the type of field $field_name doesn\'t match (nullable vs non-nullable)');
              continue;
            }

            // These should be non-user-facing errors:
            var ifield_type_name = switch (ifield.type) { case TPath(n): n; default: throw 'Interfaces can only specify TPaths'; }
            var tfield_type_name = switch (tfield.type) { case TPath(n): n; default: throw 'Interface implementations can only specify TPaths'; }

            if (ifield_type_name!=tfield_type_name) { // check for covariance
              // Since interfaces can't implement interfaces, and unions can only contain Object types,
              // the only two flavors of covariance supported are:
              //  - interface specifies an interface, type specifies an object type
              //  - interface specifies an union, type specifies an object type
              var err = 'Covariance failed on $tname field [$field_name:$tfield_type_name] for interface $iname [$field_name:$ifield_type_name]';

              if ( !is_object_type(tfield_type_name) ) {
                error(err);
              } else {
                if (is_interface(ifield_type_name) && implements_interface(tfield_type_name, ifield_type_name)) {
                  // covariance ok
                  // trace('COVAIRANCE OK! $tfield_type_name implements $ifield_type_name');
                } else if (is_union(ifield_type_name) && is_member_of_union(tfield_type_name, ifield_type_name)) {
                  // covariance ok
                  // trace('COVAIRANCE OK! $tfield_type_name is a member of $ifield_type_name');
                } else {
                  error(err);
                }
              }
            }
          }
        }
      }
    }
  }

  private function get_def_name(def) return def.name.value;

  private function error(s:String, and_throw=false) {
    _stderr_writer.append(s);
    if (and_throw) throw s;
  }

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
      error('Cannot define type $name twice!');
    }
  }

  function parse_field_type(type:ASTDefs.TypeNode, def_name:String):GQLFieldType
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

    if (field_type.type==null) error('Malformed GQL definition - did not find the named type while parsing definition: ${ def_name }!');
    return field_type;
  }

  function write_fragment_as_haxe_typedef(def:ASTDefs.FragmentDefinitionNode)
  {
    var on_type = def.typeCondition.name.value;
    var tname = '${ FRAGMENT_PREFIX }${ def.name.value }';

    // Fragments can have fragments... Do the order of these calls need to be determinant?
    generate_type_based_on_selection_set(tname,
                                         { debug_name:tname, is_operation:false },
                                         def.selectionSet,
                                         on_type);
  }

  /**
   * various node types passed in here... object types, interfaces, query args, etc
   */
  function ingest_tstruct_like_type(def:{ name:graphql.NameNode,
                                          kind:String,
                                          fields:Array<graphql.FieldDefinitionNode>,
                                          ?interfaces:Array<graphql.NamedTypeNode> }):FieldArguments
  {
    var args:FieldArguments = [];

    // Per GraphQL spoec: only Object types may implement interfaces
    if (def.kind==ASTDefs.Kind.OBJECT_TYPE_DEFINITION) {
      _interfaces_implemented[def.name.value] = [];
      if (def.interfaces!=null) {
        for (intf in def.interfaces) {
          var ifname = intf.name.value;
          _interfaces_implemented[def.name.value].push(ifname);
        }
      }
    }

    var fields = new StringMapAA<GQLFieldType>();
    define_type(TStruct(def.name.value, fields));

    for (field in def.fields) {
      var type = parse_field_type(field.type, def.name.value);
      var field_name = field.name.value;
      if (fields[field_name]!=null) error('Error, type ${ def.name.value } defines field ${ field_name } more than once!');
      fields[field_name] = type; //.clone().follow();

      if (field.arguments!=null && field.arguments.length>0) {
        args.push({ field:field_name, arguments:field.arguments });
      }
    }

    return args;
  }

  function ingest_enum_type_def(def:ASTDefs.EnumTypeDefinitionNode) {
    // trace('Generating enum: '+def.name.value);
    var values = [];
    define_type(TEnum(def.name.value, values));
    for (enum_value in def.values) {
      values.push(enum_value.name.value);
    }
  }

  function ingest_scalar_type_def(def:ASTDefs.ScalarTypeDefinitionNode) {
    // trace('Generating scalar: '+def.name.value);
    define_type(TScalar(def.name.value));
    //_stdout_writer.append('/* scalar ${ def.name.value } */\nabstract ${ def.name.value }(Dynamic) { }');
  }

  function ingest_union_type_def(def:ASTDefs.UnionTypeDefinitionNode) {
    var values = [];
    for (type in def.types) {
      if (type.name==null) {
        error('Expecting Named Types in Union ${ def.name.value }');
      } else {
        values.push(type.name.value);
      }
    }
    generate_union_of_types(values, def.name.value);
  }

  // values and return are all TPath Strings
  function generate_union_of_types(values:Array<String>, tname:String=null):String
  {
    if (tname==null) {
      values.sort(function(a,b) return a>b ? 1 : -1);
      tname = GENERATED_UNION_PREFIX+values.join(DEFAULT_SEPARATOR);
      if (_defined_types.indexOf(tname)>=0) error('Cannot redefine union $tname');
    }
    _map_of_union_types[tname] = values;
    define_type(TUnion(tname, values));
    return tname;
  }

  // A schema definition is just a mapping / typedef alias to specific types
  function ingest_schema_def(def:ASTDefs.SchemaDefinitionNode):SchemaMap {
    var rtn = { query_type:null, mutation_type:null };

    //_stdout_writer.append('/* Schema: */');
    for (ot in def.operationTypes) {
      var op = Std.string(ot.operation);
      switch op {
        case "query" | "mutation": //  | "subscription": is "non-spec experiment"
        // See if we want to bring back this type alias later... It's really a "utility" alias...
        //var capitalized = op.substr(0,1).toUpperCase() + op.substr(1);
        //_stdout_writer.append('typedef Schema${ capitalized }Type = ${ ot.type.name.value };');
        if (op=="query") rtn.query_type = ot.type.name.value;
        if (op=="mutation") rtn.mutation_type = ot.type.name.value;
        default: error('Unexpected schema operation: ${ op }');
      }
    }

    return rtn;
  }

  function resolve_type(t:GQLTypeRef, err_prefix:String=""):GQLTypeDefinition return switch (t) {
    case TPath(name):
      var rtn = _types_by_name.get(name);
      if (rtn==null) error('${ err_prefix }Error: type not found: ${ name }', true);
      rtn;
    case TAnon(def): def;
  }

  function resolve_field(path:Array<String>, ?gt_info:GenTypeInfo):GQLFieldType
  {
    var ptr:GQLTypeDefinition = null;

    var err_prefix = gt_info!=null ? 'Error processing operation ${ gt_info.debug_name }: ' : "";

    var orig_path = path.join('.');
    while (path.length>0) {
      var name = path.shift();
      if (ptr==null) { // select from root types
        ptr = _types_by_name.get(name);
        if (ptr==null) error('${ err_prefix }Didn\'t find root type ${ name } while resolving ${ orig_path }', true);
        if (path.length==0) return { is_array:false, is_optional:false, type:TPath(name) };
      } else {
        switch ptr {
          case TBasic(tname) | TScalar(tname) | TEnum(tname, _):
            error('${ err_prefix }Expecting type ${ tname } to have field ${ name }!', true);
          case TStruct(tname, fields):                
          var field:GQLFieldType;
          if(name == '__typename') {
            field =  { type:TPath('String'), is_array:false, is_optional:true };
          } else {
            field = fields[name];
          }
          if (field==null) error('${ err_prefix }Expecting type ${ tname } to have field ${ name }!', true);
          if (path.length==0) {
              resolve_type(field.type, err_prefix);
              return field;
            }
            ptr = resolve_type(field.type, err_prefix);
            if (ptr==null) error('${ err_prefix }Did not find type ${ field.type } referenced by ${ tname }.${ name }!', true);
          case TUnion(tname, _):
            error('TODO: deterimne if graphql lets you poke down into common fields of unions...', true);
        }
      }
    }

    error('${ err_prefix }couldn\'t resolve path: ${ orig_path }', true);
    return null;
  }

  function get_fragment_info(sel_node:SelectionNode)
  {
    var info = null;
    if (sel_node.kind==Kind.FRAGMENT_SPREAD) {
      var name:String = FRAGMENT_PREFIX+(cast sel_node).name.value;

      var concrete = null;
      for (frag in _fragment_defs) {
        if (frag.name.value==(cast sel_node).name.value) {
          concrete = frag.typeCondition.name.value;
        }
      }

      if (concrete==null) error('Error, did not find fragment spread named: ${ name }', true);

      info = {
        concrete:concrete,
        selectionSet:_fragment_defs.find(function(def) {
          return def.name.value==(cast sel_node).name.value;
        }).selectionSet
      }
      return info;
    }
    if (sel_node.kind==Kind.INLINE_FRAGMENT) {
      info = { concrete:(cast sel_node).typeCondition.name.value, selectionSet:(cast sel_node).selectionSet }
      return info;
    }

    error('Error determining fragment info for fragment node: ${ sel_node }', true);
    return null;
  }

  // Fragments / unification:
  //
  // Notes / quotes from spec:
  //
  //  1) unions do not contain interfaces or scalar, only object(struct) types:
  //       https://github.com/graphql/graphql-js/issues/451
  //       http://facebook.github.io/graphql/June2018/#sec-Unions
  //     "The member types of a Union type must all be Object base types; Scalar,
  //     Interface and Union types must not be member types of a Union."
  //
  //  2) interfaces can not implement other interfaces:
  //       https://github.com/graphql/graphql-js/issues/778 (not yet)
  //       http://facebook.github.io/graphql/June2018/#sec-Interfaces
  //
  //  3) "Fragments can reference each other, but cycles are not allowed"
  //
  //  4) "The target type of fragment must have kind UNION, INTERFACE, or OBJECT."
  //

  function is_union(t:String) return _map_of_union_types.exists(t);
  function is_interface(t:String) return _list_of_interfaces.indexOf(t)>=0;
  function is_object_type(t:String) return switch (_types_by_name[t]) {
    case TStruct(_): !is_interface(t);
    default: false;
  }

  // Not recursive because interfaces can't implement interfaces
  function implements_interface(t:String, i:String)
  return is_interface(i) &&
         _interfaces_implemented.exists(t) &&
         _interfaces_implemented[t].indexOf(i)>=0;

  // Not recursive because unions must only consist of Object types
  function is_member_of_union(t:String, u:String) {
    if (!is_union(u)) return false;
    for (member in _map_of_union_types[u]) if (member==t) return true;
    return false;
  }

  function check_constraint(obj_type:String, constraint_type:String)
  {
    // Umm, sure you can fragment on the current type
    if (obj_type==constraint_type) return true;

    if (!is_object_type(obj_type)) error('Check_constraint is only valid on Object types, not ${ obj_type }');

    // If constraint_type is an interface, obj_type must implement it to satisfy constraint:
    if (is_interface(constraint_type)) {
      return implements_interface(obj_type, constraint_type);
    }

    // If constraint_type is a union, obj_type must be a member:
    if (is_union(constraint_type)) {
      return _map_of_union_types[constraint_type].indexOf(obj_type)>=0;
    }

    return false;
  }

  function resolve_fragment_nodes(selections:Array<SelectionNode>,
                                  ancestor_types:Array<String>,
                                  constrained_fields:Array<ConstrainedFieldType>)
  {
    if (selections==null || selections.length==0) return;

    for (sel_node in selections) {
      if (sel_node.kind==Kind.FIELD) {
        var field = cast sel_node;
        constrained_fields.push({ constraints:ancestor_types, field_node:field, usage:0 });
      } else if (sel_node.kind==Kind.FRAGMENT_SPREAD || sel_node.kind==Kind.INLINE_FRAGMENT) {
        var info = get_fragment_info(sel_node);
        var next_ancestor_types = ancestor_types.slice(0);
        next_ancestor_types.push(info.concrete);
        resolve_fragment_nodes(info.selectionSet.selections, next_ancestor_types, constrained_fields);
      }
    }
  }

  function get_possible_object_types_from(base_type)
  {
    if (is_interface(base_type)) { // return all object types that implement base_type
      var rtn = [];
      for (t in _interfaces_implemented.keys()) {
        var ifs = _interfaces_implemented[t];
        if (ifs.indexOf(base_type)>=0) rtn.push(t);
      }
      if (rtn.length==0) {
        error('Query or fragment on interface ${ base_type }, did not find any Object types that implement it!');
      }
      return rtn;
    }

    if (is_union(base_type)) { // return all member object types of union base_type
      var rtn = [];
      for (member in _map_of_union_types[base_type]) {
        if (!is_object_type(member)) {
          error('Union ${ base_type } may not contain any type (${ member }) other than object types, per GraphQL spec');
        } else {
          rtn.push(member);
        }
      }
      return rtn;
    }

    switch (_types_by_name[base_type]) {
      case TStruct(_): return [base_type];
      default:
        error('Cannot create fragment or operation on non-Object type ${ base_type }', true);
        return null;
    }
  }

  function generate_type_based_on_selection_set(type_name:String,
                                                gt_info:GenTypeInfo,
                                                sel_set:{ selections:Array<SelectionNode> },
                                                base_type:String,
                                                depth:Int=0):GQLTypeDefinition
  {
    if (_basic_types.indexOf(base_type)>=0) {
      error('Cannot create a fragment or operation ${ gt_info.debug_name } on a basic type, ${ base_type }', true);
    }

    var possible_object_types = get_possible_object_types_from(base_type);

    // Recursively find fields under all fragments
    var constrained_fields:Array<ConstrainedFieldType> = [];
    resolve_fragment_nodes(sel_set.selections, [], constrained_fields);

    // Populate fields into possible_object_types
    var field_nodes_per_object_type = new StringMapAA<Array<SelectionNode>>();
    for (cf in constrained_fields) {
      for (obj_type in possible_object_types) {
        var valid = true;
        for (constraint in cf.constraints) {
          if (!check_constraint(obj_type, constraint)) {
            valid = false;
            break;
          }
        }
        if (valid) {
          cf.usage++;
          if (!field_nodes_per_object_type.exists(obj_type)) field_nodes_per_object_type[obj_type] = [];
          field_nodes_per_object_type[obj_type].push(cf.field_node);
        }
      }
    }

    // Error on unselected obj_types, and unused field specifications
    for (obj_type in possible_object_types) {

      if (!field_nodes_per_object_type.exists(obj_type) || field_nodes_per_object_type[obj_type]==null) {
        // Is this is allowed for unions -- to not specify any fields for one particular case?
        if (is_union(base_type)) {
          field_nodes_per_object_type[obj_type] = [];
        } else {
          error('Error: fragment or op ${ gt_info.debug_name } selected no fields for possible object type ${ obj_type }');
        }
      }
    }

    // Error on unused field specifications
    for (cf in constrained_fields) {
      if (cf.usage==0) {
        error('Error: fragment or op ${ gt_info.debug_name } specified field ${ (cast cf.field_node).name.value } that didn\'t get used in possible types [${ possible_object_types.join(", ") }] via constraints [${ cf.constraints.join(", ") }]');
      }
    }

    var fields_per_object_type = new StringMapAA<StringMapAA<GQLFieldType>>();

    var defined_names = [];
    for (obj_type in possible_object_types) {
      var fields = new StringMapAA<GQLFieldType>();
      fields_per_object_type[obj_type] = fields;
      var type_path = [ obj_type ];
      var define_name = (possible_object_types.length==1) ? type_name : type_name+UNION_SELECTION_SEPARATOR+obj_type;
      defined_names.push(define_name);
      define_type(TStruct(define_name, fields));

      var ignore_duplicates = [];

      if (field_nodes_per_object_type[obj_type]==null && is_union(base_type)) continue;

      for (sel_node in field_nodes_per_object_type[obj_type]) {
        switch (sel_node.kind) { // Field | FragmentSpread | InlineFragment
        case Kind.FIELD:
          var field_node:FieldNode = cast sel_node;
          var has_sub_selections = field_node.selectionSet!=null && field_node.selectionSet.selections!=null && field_node.selectionSet.selections.length>0;

          var name:String = field_node.name.value;
          var alias:String = field_node.alias==null ? name : field_node.alias.value;

          if (gt_info.is_operation) validate_directives(field_node, gt_info);

          // Ignore fields specified more than once (with the same alias)
          var dup_key = '$name -> $alias';
          if (ignore_duplicates.indexOf(dup_key)>=0) continue;
          ignore_duplicates.push(dup_key);

          var next_type_path = type_path.slice(0);
          next_type_path.push(name);
          var resolved = resolve_field(next_type_path, gt_info);
          var type = resolve_type(resolved.type);
          switch type {
            case TBasic(tname) | TScalar(tname) | TEnum(tname, _):
              if (has_sub_selections) {
                error('Cannot specify sub-fields of ${ tname } at ${ type_path.join(".") } of operation ${ gt_info.debug_name }', true);
              }
              fields[alias] = resolved;
            case TStruct(tname, _) | TUnion(tname, _):
              if (!has_sub_selections) {
                error('Must specify sub-fields of ${ tname } at ${ type_path.join(".") } of operation ${ gt_info.debug_name }', true);
              }
              if (is_union(tname)) {
                if (field_node.selectionSet.selections.find(function(sn) { 
                  return sn.kind==Kind.FIELD && Reflect.field(cast sn, 'name').value!='__typename'; 
                })!=null) {
                  error('Can only specify fragment selections of union ${ tname } at ${ type_path.join(".") } of operation ${ gt_info.debug_name }', true);
                }
              }

              var sub_type_name = (depth==0 && StringTools.endsWith(type_name, OP_OUTER_SUFFIX)) ?
                StringTools.replace(type_name, OP_OUTER_SUFFIX, OP_INNER_SUFFIX) : type_name+DEFAULT_SEPARATOR+name;
  
              var sub_type = generate_type_based_on_selection_set(sub_type_name, gt_info, field_node.selectionSet, tname, depth+1);
              var f = { type:null, is_array:resolved.is_array, is_optional:resolved.is_optional };
              fields[alias] = f;
              if (is_union(sub_type_name)) {
                f.type = TPath(sub_type_name);
              } else if (depth==0) { // Make separate, named type for first-level of query
                f.type = TPath(sub_type_name);
              } else { // undefine and merge into my type
                _types_by_name.remove(sub_type_name);
                _defined_types.remove(sub_type_name);
                f.type = TAnon(sub_type);
              }
          }
          case Kind.INLINE_FRAGMENT | Kind.FRAGMENT_SPREAD: error('Should not get fragment nodes here...', true);
          default: error('Unhandled sel_node kind ${ sel_node.kind }', true);
        }
      }
    }

    if (possible_object_types.length>1) {
      generate_union_of_types(defined_names, type_name);
      return _types_by_name[type_name];
    } else {
      return _types_by_name[type_name];
    }
    
  }

  // Per the discussion at https://github.com/facebook/graphql/issues/204, the operation
  // variables are global, and any variables used herein (both in fragments or regular fields)
  // must be defined in the operation variables.
  function validate_directives(field_node:FieldNode, gt_info:GenTypeInfo)
  {
    if (field_node.directives!=null) {
      for (dir in field_node.directives) {
        if (dir.arguments!=null) for (arg in dir.arguments) {
          // here, arg.name.value is 'if', and arg.value.name.value is 'my_param'
          var param = (cast arg.value).name.value;
          //trace('Found param: ${ param }');
          var valid = false;
          for (vrr in gt_info.op_variables) if (vrr.variable.name.value==param) valid = true;
          if (!valid) error('Error: operation ${ gt_info.debug_name } is expecting parameter ${ param } which hasn\'t been defined in the operation variables!');
        }
      }
    }
  }

  function write_operation_def_result(root_schema:SchemaMap,
                                      root:ASTDefs.DocumentNode,
                                      def:ASTDefs.OperationDefinitionNode):OpVariables
  {
    if (def.name==null || def.name.value==null) {
      error('Unnamed / anonymous operations are not supported...', true);
    }

    var op_name = def.name.value;

    var op_root_type = '';
    if (def.operation=='query') {
      op_root_type = (root_schema==null || root_schema.query_type==null) ? 'Query' : root_schema.query_type;
    } else if (def.operation=='mutation') {
      op_root_type = (root_schema==null || root_schema.mutation_type==null) ? 'Mutation' : root_schema.mutation_type;
    } else {
      error('Error processing ${ op_name }: Only query and mutation are supported.', true);
    }

    // gen type based on selection set
    generate_type_based_on_selection_set('${ OP_PREFIX }${ op_name }${ OP_OUTER_SUFFIX }',
                                         { debug_name:op_name, is_operation:true, op_variables:def.variableDefinitions },
                                         def.selectionSet,
                                         op_root_type);

    return { op_name:op_name, variables:def.variableDefinitions };
  }

  function print_to_stdout():String {
    var stdout_writer = new StringWriter();
    stdout_writer.append('/* - - - - Haxe / GraphQL compatibility types - - - - */
abstract ID(String) to String from String {\n  // Relaxed safety -- allow implicit fromString
  //  TODO: optional strict safety -- require explicit fromString:
  //  public static inline function fromString(s:String) return cast s;
  //  public static inline function ofString(s:String) return cast s;
}');
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

typedef GenTypeInfo = {
  debug_name:String,
  is_operation:Bool, // when false, it's a fragment
  ?op_variables:Array<VariableDefinitionNode>
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

  public function toString():String return _output.join("\n");
}


// These will map to ComplexTypes:
//  String        --> TPath(name)                    if not array, not optional
//  Array<String> --> TPath('Array', [TPath(name)])  if array
//  optional adds metadata to field
enum GQLTypeRef {
  TPath(name:String);
  TAnon(type:GQLTypeDefinition); // Nested structures, only in selections (query / mutation / fragment)
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

class GQLTypeTools
{
  public static var bool_collision = false;
  public static function gql_to_haxe_type_name_transforms(tname:String):String
  {
    if (tname=="Bool" && bool_collision) return "Bool"+HaxeGenerator.DEFAULT_SEPARATOR;
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
        var ct = TAnonymous(fields);
        if (gql_f.is_array) ct = TPath({ pack:[], name:'Array', params:[ TPType(ct) ] });
        var field = { name:field_name, kind:FVar(ct, null), meta:[], pos:FAKE_POS };
        if (gql_f.is_optional) field.meta.push({ name:":optional", pos:FAKE_POS });
        return field;
      case TAnon(any): throw 'Non-struct types are not supported in TAnon: ${ any }';
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
          writer.append(' @:from static inline function from${ type_name }(v:${ type_name }):${ tname } return cast v;');
          var as_name = type_name;
          var sep:String = HaxeGenerator.UNION_SELECTION_SEPARATOR;
          if (as_name.indexOf(sep)>=0) {
            as_name = as_name.substr(as_name.indexOf(sep)+sep.length);
          }
          writer.append(' public inline function as${ HaxeGenerator.DEFAULT_SEPARATOR }${ as_name }():${ type_name } return cast this;');

        }

        var tps = type_paths.toString();
        var as_either_template = ' public inline function as_either():Either<::(tps)::> { 
          if(this.__typename == "::(type_paths[0])::)") {
            return Left(this);
          } else if(this.__typename == "::(type_paths[1])::") {
            return Right(this);
          } else {
            throw "invalid type";
          }
        }
        ';
        var either =new haxe.Template(as_either_template);
        writer.append(either.execute({tps:tps}));

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

typedef ConstrainedFieldType = { constraints:Array<String>, field_node:SelectionNode, usage:Int }

// - - - -
// Utils
// - - - -


// StringMap with Array Access
@:forward
abstract StringMapAA<T>(haxe.ds.StringMap<T>) from haxe.ds.StringMap<T> to haxe.ds.StringMap<T> {
  public function new() { this = new haxe.ds.StringMap<T>(); }
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
