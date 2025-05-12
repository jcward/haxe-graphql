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

 0.0.25 - Parser ignore/allow interface implements other interfaces / issue #48  
 0.0.24 - Added support for Unions via __typename / as_enum() / issue #43  
 0.0.23 - Updated to graphql-js v14.3.0, block string support thanks to github.com/darmie  
 0.0.22 - Improved error reporting / issue #35  
 0.0.21 - Added support for graphql 'extend type' / issue #33  
 0.0.20 - Added union .as__T cast helper functions  
 0.0.19 - Fixed fragment definition order should not matter / issue #31  
 0.0.18 - Implemented validation of directive parameters / issue #25  
 0.0.17 - Fixed cannot select from union types / issue #30  
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
