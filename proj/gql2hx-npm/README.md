gql2hx - GraphQL to Haxe CLI
-----------

Convert GraphQL schema to Haxe definitions. Try it [live in your browser!](http://jcward.com/gql2hx/)

**Status:** alpha

Usage:
---

```
  Usage: gql2hx -i <file> [-o <outfile>]

    -i, --infile [infile]      Input .graphql file (or "stdin") (default: null)
    -o, --outfile [outfile]    Output .hx file (or "stdout") (default: stdout)
```

Coming soon: generate typedefs or classess & interfaces.

Development sponsored by: [www.wootmath.com](https://www.wootmath.com) [simbulus.com](https://simbulus.com/)

Release notes: 
---

 0.0.10 - Added -p option for --parse-only  
 0.0.9  - Generate query vars type (also renamed prefixes/suffixes)  
 0.0.8  - README updates  
 0.0.7  - Support typing queries (expected query results)  
