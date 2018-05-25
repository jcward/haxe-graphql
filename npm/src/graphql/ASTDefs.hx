package graphql;

class ASTDefs { }

// TODO: look at auto-generating these from DefinitelyTyped/types/graphql/language/ast.d.ts

// But for now, fill out only the parts we're using so far:
typedef TODO = Dynamic;

typedef Document = {
  definitions:Array<TODO>
}

typedef Location = { start:Int, end:Int, startToken:TODO, endToken:TODO, source:TODO }

typedef BaseNode = {
  kind:Kind,
  ?loc:Location
}

typedef BaseValueNode = { > BaseNode,
  value:String
}

typedef WithNameAndDescription = {
  ?description: StringValueNode,
  ?name: NameNode,
}

typedef WithDirectives = {
    /* readonly */ ?directives: ReadonlyArray<DirectiveNode>,
}

typedef NameNode = { > BaseValueNode, }

typedef StringValueNode = { > BaseValueNode,
    /* readonly */ ?block:Bool
}

typedef ArgumentNode = { > BaseValueNode,
  value:String,
  name:String
}

typedef DirectiveNode = { > NameNode,
  name:String,
  ?arguments: ReadonlyArray<ArgumentNode>
}

// Type Reference

typedef TypeNode = { > BaseNode,
    // Calling these optionals makes us able to simply null-check them:
    /* readonly */ ?name: NameNode, // Only for NamedTypeNode
    /* readonly */ ?type: TypeNode, // Not for NamedTypeNode
}

typedef NamedTypeNode = { > TypeNode,
    /* readonly */ name: NameNode,
}

typedef ListTypeNode = { > TypeNode,
    /* readonly */ type: TypeNode,
}

typedef NonNullTypeNode = { > TypeNode,
    /* readonly */ type: TypeNode // NamedTypeNode | ListTypeNode,
}

typedef InputValueDefinitionNode = TODO;
typedef FieldDefinitionNode = { > BaseNode, // kind=='FieldDefinition'
    > WithNameAndDescription,
    ?arguments: ReadonlyArray<InputValueDefinitionNode>,
    type: TypeNode,
    ?directives: ReadonlyArray<DirectiveNode>
}

@:forward(length, concat, join, toString, indexOf, lastIndexOf, copy, iterator, map, filter)
abstract ReadonlyArray<T>(Array<T>) from Array<T> to Iterable<T> {
	@:arrayAccess @:extern inline public function arrayAccess(key:Int):T return this[key];
}

typedef ObjectTypeDefinitionNode = { > BaseNode, // kind="ObjectTypeDefinition"
    > WithNameAndDescription,
    > WithDirectives,
    /* readonly */ ?interfaces: ReadonlyArray<NamedTypeNode>,
    /* readonly */ ?fields: ReadonlyArray<FieldDefinitionNode>
}

typedef EnumValueDefinitionNode = { > BaseNode,  // kind="EnumValueDefinition"
    > WithNameAndDescription,
    > WithDirectives,
}

typedef EnumTypeDefinitionNode = { > BaseNode,  // kind="EnumTypeDefinition"
    > WithNameAndDescription,
    > WithDirectives,
    /* readonly */ ?values: ReadonlyArray<EnumValueDefinitionNode>
}

typedef UnionTypeDefinitionNode = { > BaseNode,  // kind="UnionTypeDefinition"
    > WithNameAndDescription,
    > WithDirectives,
    ?types: ReadonlyArray<NamedTypeNode>
}


@:enum abstract Kind(String) {
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
