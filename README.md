# haxe-graphql

Tools for parsing GraphQL schema and queries into Haxe type definitions.

**Status:** alpha - see various projects for their feature / compatibility notes.

[![Build Status](https://travis-ci.com/jcward/haxe-graphql.svg?branch=master)](https://travis-ci.com/jcward/haxe-graphql)

[Try gql2hx live in your browser!](http://jcward.com/gql2hx/)

[<img src="./proj/webdemo/demo.gif" width=450 alt="gql2hx web demo">](http://jcward.com/gql2hx/)

See the various directories under `./proj`:

- [hxgen](./proj/hxgen) - Haxe Code Generator (from GraphQL AST)
- [parser](./proj/parser) - Pure-Haxe GraphQL parser (.graphql to GraphQL AST, built on tink_parse)
- [gql2hx-npm](./proj/gql2hx-npm) - NPM module packaging the Haxe Generator (uses official graphql module for parsing)
- [gql2hx-haxelib](./proj/gql2hx-haxelib) - Haxelib module providing macro-time access to these tools (uses Haxe-based parser)
- [ast](./proj/ast) - GraphQL AST Definitions
- [webdemo](./proj/webdemo) - live demo of .graphql -> Haxe code
