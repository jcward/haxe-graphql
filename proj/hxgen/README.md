GraphQL to Haxe: Haxe Generator
-----------

Takes GraphQL schema definition AST and turn it into Haxe code.

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

Options:
----

```
type HxGenOptions {
  type: TypeOutput     # Default: typedefs
  null_wraps: Boolean  # Default: true
}

enum OutputTyping {
  typedefs
  classes
}
```
