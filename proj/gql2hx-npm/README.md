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

 0.0.16 - Fixed inner array types / issue #27  
 0.0.15 - Implemented fragment support and interface checking /w covariance  
 0.0.14 - Fixed query result array types / issue #23  
 0.0.13 - Mutation support enabled / issue #20  
 0.0.12 - Enums now generate @:enum abstract(String) / issue #22  
 0.0.11 - Removed typedef 'extension' notion for interfaces - see fa538e5  
 0.0.10 - Added -p option for --parse-only  
 0.0.9  - Generate query vars type (also renamed prefixes/suffixes)  
 0.0.8  - README updates  
 0.0.7  - Support typing queries (expected query results)  
