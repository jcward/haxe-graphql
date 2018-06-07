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
- [x] Queries
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

Example
----

Input, parsed AST from:

```
schema {
  query: MyQueries
}

scalar Date

enum ReleaseStatus {
  PRE_PRODUCTION
  IN_PRODUCTION
  RELEASED
}

interface IHaveID {
  id:ID!
}

type FilmData implements IHaveID {
  id:ID!
  title:String!
  director:String
  releaseDate:Date
  releaseStatus:ReleaseStatus
}

type MyQueries {
  film: [FilmData]
}

query GetFilmsByDirector($director: String) {
  film(director: $director) {
    title
    director
    releaseDate
  }
}
```

Output Haxe:

```
/* - - - - Haxe / GraphQL compatibility types - - - - */
abstract IDString(String) to String {
  // Strict safety -- require explicit fromString
  public static inline function fromString(s:String) return cast s;
  public static inline function ofString(s:String) return cast s;
}
typedef ID = IDString;
typedef Boolean = Bool;
/* - - - - - - - - - - - - - - - - - - - - - - - - - */


/* Schema: */
typedef SchemaQueryType = MyQueries;

typedef IHaveID = {
  id: ID
}

/* scalar Date */
abstract Date(Dynamic) { }

enum ReleaseStatus {
  PRE_PRODUCTION;
  IN_PRODUCTION;
  RELEASED;
}

typedef FilmData = {
  /* implements interface */ > IHaveID,
  title: String,
  ?director: String,
  ?releaseDate: Date,
  ?releaseStatus: ReleaseStatus
}

typedef MyQueries = {
  ?film: Array<FilmData>
}

/* Operation def: */
typedef QueryResult_GetFilmsByDirector = {
  ?film:Array<{ /* subset of FilmData */
    title:String,
    ?director:String,
    ?releaseDate:Date,
  }>
}```
