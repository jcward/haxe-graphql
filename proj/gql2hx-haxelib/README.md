See [the repo](https://github.com/jcward/haxe-graphql) for an explanation of the haxe-graphql project and gql2hx libraries.

This haxelib is deprecated (or onhold, awaiting someone who needs it bad enough to implement it.)

The vision for this haxelib was to be a macro library to generate types from
.gql files at macro-time. For our purposes, we ended up using
[the NPM library](https://www.npmjs.com/package/gql2hx) to generate .hx
files before envoking the Haxe compiler.
