Parsing GraphQL to GQL AST
---------

How best to parse GraphQL to AST is an interesting question. Using
the official [npm graphql module](https://www.npmjs.com/package/graphql) will be
most accurate, and least effort. So that's what we use in gql2hx ([source](../gql2hx-npm), [npmjs.com](https://www.npmjs.com/package/gql2hx)).

There also exists a libgraphql C++ library, but it's [only](https://github.com/graphql/libgraphqlparser/#requirements) for Linux / OSX.

However, a native Haxe implementation of a graphql parser will allow more
interesting and flexible use cases:

- Generating Haxe types from HQL at macro time.
  - Technically you could call out to npm or a web api, but that'd be slow.
- A live, browser-based GQL to Haxe code.
  - Although, perhaps the graphql module compiles to browser-friendly js?
