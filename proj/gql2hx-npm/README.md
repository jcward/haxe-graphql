gql2hx - GraphQL to Haxe CLI
-----------

Convert GraphQL schema to Haxe definitions.

Status: alpha

GraphQL schema support:
- [x] Basic schema
  - [x] type, interface, union, enum
    - [ ] review covariance of interface field and type field
  - [x] lists and not-nulls
  - [ ] scalar
  - [ ] schema
- [ ] Arguments
- [ ] Queries
- [ ] Yadda yadda

Coming soon: generate typedefs or classess & interfaces.

Usage:
---

```
  Usage: gql2hx -i <file> [-o <outfile>]

    -i, --infile [infile]      Input .graphql file (or "stdin") (default: null)
    -o, --outfile [outfile]    Output .hx file (or "stdout") (default: stdout)
```
