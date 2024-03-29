# haxe-graphql

Tools for parsing GraphQL schema and queries into Haxe type definitions.

**Status:** alpha - see various projects for their feature / compatibility notes.

[![Build Status](https://travis-ci.com/jcward/haxe-graphql.svg?branch=master)](https://travis-ci.com/jcward/haxe-graphql)

Try gql2hx [live in your browser](http://jcward.com/gql2hx/) or via NPM: `npm install -g gql2hx`


[<img src="./proj/webdemo/demo.gif" width=450 alt="gql2hx web demo">](http://jcward.com/gql2hx/)

See the various directories under `./proj`:

- [hxgen](./proj/hxgen) - Haxe Code Generator (from GraphQL AST)
- [parser](./proj/parser) - Pure-Haxe GraphQL parser (direct port from graphql-js v14.3.0)
- [gql2hx-npm](./proj/gql2hx-npm) - NPM module packaging the Haxe Generator
- [gql2hx-haxelib](./proj/gql2hx-haxelib) - (Placeholder / TBD) Haxelib module providing macro-time access to these tools
- [ast](./proj/ast) - GraphQL AST Definitions
- [webdemo](./proj/webdemo) - live demo of .graphql -> Haxe code

**Development sponsored by:**

[<img src="http://www.wootmath.com/dds/a1/84/86f31a3b3dc73a74ff996f1bd2db.png" width=120 alt="Woot Math">](https://www.wootmath.com)  

[<img src="https://simbulus.com/img/consulting/simbulus-logo.png" alt="Simbulus Consulting">](https://simbulus.com/)
