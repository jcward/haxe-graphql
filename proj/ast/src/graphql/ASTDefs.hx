package graphql;

class ASTDefs { }

typedef TODO = Dynamic;

typedef ReadonlyArray<T> = Array<T>;

// TODO / TBD
typedef Document = { definitions:Array<TODO> }
typedef TokenKindEnum = String;
typedef Source = Dynamic;
typedef OperationTypeNode = Dynamic;

// Hmm, workaround for node type unions
typedef BaseNode = {
  kind:String,
  ?loc:Location
}

// Type nodes
typedef TypeNode = { > BaseNode,
  // Calling these optionals makes us able to simply null-check them:
  ?name: NameNode, // Only for NamedTypeNode
  ?type: TypeNode, // Not for NamedTypeNode
}

typedef NonNullTypeNode = { > TypeNode,
    /* readonly */ type: TypeNode // NamedTypeNode | ListTypeNode,
}

// Kind
@:enum abstract Kind(String) to String from String {
  // Name
  var NAME = 'Name';

  // Document
  var DOCUMENT = 'Document';
  var OPERATION_DEFINITION = 'OperationDefinition';
  var VARIABLE_DEFINITION = 'VariableDefinition';
  var VARIABLE = 'Variable';
  var SELECTION_SET = 'SelectionSet';
  var FIELD = 'Field';
  var ARGUMENT = 'Argument';

  // Fragments
  var FRAGMENT_SPREAD = 'FragmentSpread';
  var INLINE_FRAGMENT = 'InlineFragment';
  var FRAGMENT_DEFINITION = 'FragmentDefinition';

  // Values
  var INT = 'IntValue';
  var FLOAT = 'FloatValue';
  var STRING = 'StringValue';
  var BOOLEAN = 'BooleanValue';
  var NULL = 'NullValue';
  var ENUM = 'EnumValue';
  var LIST = 'ListValue';
  var OBJECT = 'ObjectValue';
  var OBJECT_FIELD = 'ObjectField';

  // Directives
  var DIRECTIVE = 'Directive';

  // Types
  var NAMED_TYPE = 'NamedType';
  var LIST_TYPE = 'ListType';
  var NON_NULL_TYPE = 'NonNullType';
  
  // Type System Definitions
  var SCHEMA_DEFINITION = 'SchemaDefinition';
  var OPERATION_TYPE_DEFINITION = 'OperationTypeDefinition';
  
  // Type Definitions
  var SCALAR_TYPE_DEFINITION = 'ScalarTypeDefinition';
  var OBJECT_TYPE_DEFINITION = 'ObjectTypeDefinition';
  var FIELD_DEFINITION = 'FieldDefinition';
  var INPUT_VALUE_DEFINITION = 'InputValueDefinition';
  var INTERFACE_TYPE_DEFINITION = 'InterfaceTypeDefinition';
  var UNION_TYPE_DEFINITION = 'UnionTypeDefinition';
  var ENUM_TYPE_DEFINITION = 'EnumTypeDefinition';
  var ENUM_VALUE_DEFINITION = 'EnumValueDefinition';
  var INPUT_OBJECT_TYPE_DEFINITION = 'InputObjectTypeDefinition';
  
  // Type Extensions
  var SCALAR_TYPE_EXTENSION = 'ScalarTypeExtension';
  var OBJECT_TYPE_EXTENSION = 'ObjectTypeExtension';
  var INTERFACE_TYPE_EXTENSION = 'InterfaceTypeExtension';
  var UNION_TYPE_EXTENSION = 'UnionTypeExtension';
  var ENUM_TYPE_EXTENSION = 'EnumTypeExtension';
  var INPUT_OBJECT_TYPE_EXTENSION = 'InputObjectTypeExtension';
  
  // Directive Definitions
  var DIRECTIVE_DEFINITION = 'DirectiveDefinition';
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Auto-generated from DefinitelyTyped/types/graphql/language/ast.d.ts
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


typedef Location = {
  start: Int,
  end: Int,
  startToken: Token,
  endToken: Token,
  source: Source,
}

typedef Token = {
  kind: TokenKindEnum,
  start: Int,
  end: Int,
  line: Int,
  column: Int,
}
typedef ASTNode = BaseNode;

// Ignored: ASTKindToNode

typedef NameNode = {
  > BaseNode,
  kind: String, // "Name"
  ?loc: Location,
  value: String,
}

typedef DocumentNode = {
  > BaseNode,
  kind: String, // "Document"
  ?loc: Location,
  definitions: ReadonlyArray<DefinitionNode>,
}
typedef DefinitionNode = BaseNode;
typedef ExecutableDefinitionNode = BaseNode;

typedef OperationDefinitionNode = {
  > BaseNode,
  kind: String, // "OperationDefinition"
  ?loc: Location,
  operation: OperationTypeNode,
  ?name: NameNode,
  ?variableDefinitions: ReadonlyArray<VariableDefinitionNode>,
  ?directives: ReadonlyArray<DirectiveNode>,
  selectionSet: SelectionSetNode,
}

typedef VariableDefinitionNode = {
  > BaseNode,
  kind: String, // "VariableDefinition"
  ?loc: Location,
  variable: VariableNode,
  type: TypeNode,
  ?defaultValue: ValueNode,
}

typedef VariableNode = {
  > BaseNode,
  kind: String, // "Variable"
  ?loc: Location,
  name: NameNode,
}

typedef SelectionSetNode = {
  > BaseNode,
  kind: String, // "SelectionSet"
  ?loc: Location,
  selections: ReadonlyArray<SelectionNode>,
}
typedef SelectionNode = BaseNode;

typedef FieldNode = {
  > BaseNode,
  kind: String, // "Field"
  ?loc: Location,
  ?alias: NameNode,
  name: NameNode,
  ?arguments: ReadonlyArray<ArgumentNode>,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?selectionSet: SelectionSetNode,
}

typedef ArgumentNode = {
  > BaseNode,
  kind: String, // "Argument"
  ?loc: Location,
  name: NameNode,
  value: ValueNode,
}

typedef FragmentSpreadNode = {
  > BaseNode,
  kind: String, // "FragmentSpread"
  ?loc: Location,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
}

typedef InlineFragmentNode = {
  > BaseNode,
  kind: String, // "InlineFragment"
  ?loc: Location,
  ?typeCondition: NamedTypeNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  selectionSet: SelectionSetNode,
}

typedef FragmentDefinitionNode = {
  > BaseNode,
  kind: String, // "FragmentDefinition"
  ?loc: Location,
  name: NameNode,
  ?variableDefinitions: ReadonlyArray<VariableDefinitionNode>,
  typeCondition: NamedTypeNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  selectionSet: SelectionSetNode,
}
typedef ValueNode = BaseNode;

typedef IntValueNode = {
  > BaseNode,
  kind: String, // "IntValue"
  ?loc: Location,
  value: String,
}

typedef FloatValueNode = {
  > BaseNode,
  kind: String, // "FloatValue"
  ?loc: Location,
  value: String,
}

typedef StringValueNode = {
  > BaseNode,
  kind: String, // "StringValue"
  ?loc: Location,
  value: String,
  ?block: Bool,
}

typedef BooleanValueNode = {
  > BaseNode,
  kind: String, // "BooleanValue"
  ?loc: Location,
  value: Bool,
}

typedef NullValueNode = {
  > BaseNode,
  kind: String, // "NullValue"
  ?loc: Location,
}

typedef EnumValueNode = {
  > BaseNode,
  kind: String, // "EnumValue"
  ?loc: Location,
  value: String,
}

typedef ListValueNode = {
  > BaseNode,
  kind: String, // "ListValue"
  ?loc: Location,
  values: ReadonlyArray<ValueNode>,
}

typedef ObjectValueNode = {
  > BaseNode,
  kind: String, // "ObjectValue"
  ?loc: Location,
  fields: ReadonlyArray<ObjectFieldNode>,
}

typedef ObjectFieldNode = {
  > BaseNode,
  kind: String, // "ObjectField"
  ?loc: Location,
  name: NameNode,
  value: ValueNode,
}

typedef DirectiveNode = {
  > BaseNode,
  kind: String, // "Directive"
  ?loc: Location,
  name: NameNode,
  ?arguments: ReadonlyArray<ArgumentNode>,
}

typedef NamedTypeNode = {
  > BaseNode,
  kind: String, // "NamedType"
  ?loc: Location,
  name: NameNode,
}

typedef ListTypeNode = {
  > BaseNode,
  kind: String, // "ListType"
  ?loc: Location,
  type: TypeNode,
}

// Ignored: NonNullTypeNode
typedef TypeSystemDefinitionNode = BaseNode;

typedef SchemaDefinitionNode = {
  > BaseNode,
  kind: String, // "SchemaDefinition"
  ?loc: Location,
  directives: ReadonlyArray<DirectiveNode>,
  operationTypes: ReadonlyArray<OperationTypeDefinitionNode>,
}

typedef OperationTypeDefinitionNode = {
  > BaseNode,
  kind: String, // "OperationTypeDefinition"
  ?loc: Location,
  operation: OperationTypeNode,
  type: NamedTypeNode,
}
typedef TypeDefinitionNode = BaseNode;

typedef ScalarTypeDefinitionNode = {
  > TypeNode,
  kind: String, // "ScalarTypeDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
}

typedef ObjectTypeDefinitionNode = {
  > TypeNode,
  kind: String, // "ObjectTypeDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?interfaces: ReadonlyArray<NamedTypeNode>,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?fields: ReadonlyArray<FieldDefinitionNode>,
}

typedef FieldDefinitionNode = {
  > BaseNode,
  kind: String, // "FieldDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?arguments: ReadonlyArray<InputValueDefinitionNode>,
  type: TypeNode,
  ?directives: ReadonlyArray<DirectiveNode>,
}

typedef InputValueDefinitionNode = {
  > BaseNode,
  kind: String, // "InputValueDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  type: TypeNode,
  ?defaultValue: ValueNode,
  ?directives: ReadonlyArray<DirectiveNode>,
}

typedef InterfaceTypeDefinitionNode = {
  > TypeNode,
  kind: String, // "InterfaceTypeDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?fields: ReadonlyArray<FieldDefinitionNode>,
}

typedef UnionTypeDefinitionNode = {
  > TypeNode,
  kind: String, // "UnionTypeDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?types: ReadonlyArray<NamedTypeNode>,
}

typedef EnumTypeDefinitionNode = {
  > TypeNode,
  kind: String, // "EnumTypeDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?values: ReadonlyArray<EnumValueDefinitionNode>,
}

typedef EnumValueDefinitionNode = {
  > BaseNode,
  kind: String, // "EnumValueDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
}

typedef InputObjectTypeDefinitionNode = {
  > TypeNode,
  kind: String, // "InputObjectTypeDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?fields: ReadonlyArray<InputValueDefinitionNode>,
}
typedef TypeExtensionNode = BaseNode;

typedef ScalarTypeExtensionNode = {
  > BaseNode,
  kind: String, // "ScalarTypeExtension"
  ?loc: Location,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
}

typedef ObjectTypeExtensionNode = {
  > BaseNode,
  kind: String, // "ObjectTypeExtension"
  ?loc: Location,
  name: NameNode,
  ?interfaces: ReadonlyArray<NamedTypeNode>,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?fields: ReadonlyArray<FieldDefinitionNode>,
}

typedef InterfaceTypeExtensionNode = {
  > BaseNode,
  kind: String, // "InterfaceTypeExtension"
  ?loc: Location,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?fields: ReadonlyArray<FieldDefinitionNode>,
}

typedef UnionTypeExtensionNode = {
  > BaseNode,
  kind: String, // "UnionTypeExtension"
  ?loc: Location,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?types: ReadonlyArray<NamedTypeNode>,
}

typedef EnumTypeExtensionNode = {
  > BaseNode,
  kind: String, // "EnumTypeExtension"
  ?loc: Location,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?values: ReadonlyArray<EnumValueDefinitionNode>,
}

typedef InputObjectTypeExtensionNode = {
  > BaseNode,
  kind: String, // "InputObjectTypeExtension"
  ?loc: Location,
  name: NameNode,
  ?directives: ReadonlyArray<DirectiveNode>,
  ?fields: ReadonlyArray<InputValueDefinitionNode>,
}

typedef DirectiveDefinitionNode = {
  > BaseNode,
  kind: String, // "DirectiveDefinition"
  ?loc: Location,
  ?description: StringValueNode,
  name: NameNode,
  ?arguments: ReadonlyArray<InputValueDefinitionNode>,
  locations: ReadonlyArray<NameNode>,
}
