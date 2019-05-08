Parsing GraphQL to GQL AST
---------

This is a pure-Haxe port of the graphql-js parser, specifically parser.js, lexer.js, and ast.js.

The translation is a set of Ruby scripts (see `gen_*.rb`), mostly regex based, and currently
targets graphql-js v14.3.0. It could possibly be updated easily as newer versions
are released, depending on the scope of the changes. You can regenerate the lexer and parser
(from the Facebook .js source code) as follows:

```
./gen_lexer.rb src/graphql/parser/GeneratedLexer.hx
./gen_parser.rb > src/graphql/parser/GeneratedParser.hx
```

Block string support was thanks to @darmie

I haven't tested any unicode. But it seems to work great!
