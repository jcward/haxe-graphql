Parsing GraphQL to GQL AST
---------

This is a pure-Haxe port of the graphql-js parser, specifically parser.js, lexer.js, and ast.js.

It currently does not support block strings (aka triple quotes `"""`) and
I haven't tested any unicode. But otherwise it seems to work great!

The translation is a set of Ruby scripts (see `gen_*.rb`), mostly regex based, and currently
targets graphql-js 0.13.2. It could possibly be updated easily as newer versions
are released, depending on the scope of the changes.
