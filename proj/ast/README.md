GraphQL AST Definitions
----

Imported via gen.rb from: DefinitelyTyped/types/graphql/language/ast.d.ts

Used by both the parser (generates GraphQL AST) and the HaxeGenerator (consumes GraphQL AST)

[ ] Review whether @:structInit classes and interfaces would be better than typedefs
  - interfaces could implement default values, e.g. `kind = "DefaultValueString"`
  - proper TypedNode hierarchy
  - what should union become? an implicit interface forced upon the unioned types?
  - probably faster performance / strictly typed
