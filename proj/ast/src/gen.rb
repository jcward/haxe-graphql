#!/usr/bin/ruby
#
# Cheap & ugly regex line-by-line parsing to grab defs from ast.d.ts
#

src = `locate ast.d.ts | grep graphql\/language | head -n 1`.chomp

raise "Couldn't locate @types/graphql/language/ast.d.ts on your filesystem... exiting..." unless src

IGNORE = [ 'ASTKindToNode', 'NonNullTypeNode' ]
TODO = []

output = []
output << <<EOF
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
EOF

type = nil
File.read(src).split("\n").each { |line|

  line.sub!(/\/\/.*$/, '')
  if (type==nil) then
    # Detect export interface
    if (line.match(/export type (\w+Node) =/)) then
      # Hack for node hierarchy / union types
      output << "typedef #{ $1 } = BaseNode;" unless $1.include?("TypeNode")
    elsif (line.match(/export interface (\w+Node|Location|Token)/)) then
      type = $1
      if (IGNORE.include?(type)) then
        output << "\n// Ignored: #{ type }"
        type = nil;
        next
      elsif (TODO.include?(type)) then
        output << "\ntypedef #{ type } = TODO;"
        type = nil;
        next
      end
      # puts "Parsing #{ $1 }"
      output << "\ntypedef #{ type } = {"
      if (type.match(/Node$/)) then
        if (type.match(/TypeDef/) && !type.match(/OperationTypeDefinitionNode/)) then
          output << "  > TypeNode,"
        else
          output << "  > BaseNode,"
        end
      end
    end
  elsif (line.match(/\s*}\s*/)) then
    # End of export interface
    output << "}"
    type = nil
  else
    # Inside export interface

    # various forms of optional:
    optional = line.include?('?:') || line.include?('| null;') || line.include?('| undefined;')

    # Special case for kind "strings"
    out = nil
    line.gsub!(/ readonly /, '')
    if (line.match(/kind:\s*("\w+")/)) then
      out = "  kind: String, // #{ $1 }"
    elsif (line.match(/^\s*(\w+)\s*(\?)?\s*:\s*([a-zA-Z0-9<>]+\s*;)/)) then
      out = "  #{ optional ? '?' : ''}#{ $1 }: #{ $3 }"
    end

    if (out) then
      out.sub!(/: number/,  ": Int")
      out.sub!(/: string/,  ": String")
      out.sub!(/: boolean/, ": Bool")
      out.sub!(/;\s*$/, ',')

      # puts "--------------"
      # puts line
      # puts out
      output << out
    end
  end
}

puts output.join("\n")
