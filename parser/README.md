Parsing GraphQL to GQL AST
---------

Hmm, this is an interesting problem. Using the npm (graphql)[https://www.npmjs.com/package/graphql] module will be
most accurate, and least effort.

The gql2hx npm module (a cli tool) uses the graphql module for parsing, and then
the HaxeGenerator to convert gql AST into Haxe code.

However, a native Haxe implementation of a graphql parser will allow more
interesting use cases:

- Generating Haxe types from HQL at macro time.
  - Technically you could call out to npm or a web api, but that'd be slow.
- A browser-based GQL to Haxe code repl.
