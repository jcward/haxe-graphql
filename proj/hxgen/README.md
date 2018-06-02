GraphQL to Haxe: Haxe Generator
-----------

Takes GraphQL schema definition AST and turn it into Haxe code.

GraphQL schema support:
- [x] Schema
  - [x] type, interface, union, enum, scalar
    - [ ] review covariance of interface field and type field
  - [x] lists and not-nulls
  - [x] scalar
  - [x] Arguments (generates type for arguments)
- [ ] Queries
- [ ] Optionally generate classes / interfaces

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
