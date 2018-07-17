GraphQL to Haxe: Haxe Generator
-----------

Takes GraphQL schema definition AST and turn it into Haxe code.

GraphQL schema support:
- [x] Schema
  - [x] type, interface, union, enum, scalar
  - [x] interface validation (with covariance)
  - [x] lists and not-nulls
  - [x] scalar
  - [x] Arguments (generates type for arguments)
- [x] Operations (generates var types and result types)
  - [x] Queries
  - [x] Mutations
  - [x] Query fragments

Example
----

Input GraphQL:

```
# Creates typedefs for all schema types

schema {
  query: MyQueries
  mutation: MyMutations
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

# - Queries - -
type MyQueries {
  film: [FilmData]
}

# Creates query response typedefs
query GetFilmsByDirector($director: String) {
  film(director: $director) {
    title
    director
    releaseDate
  }
}

# - Mutations - -
type MyMutations {
  insert_film(title:String!, director:String, releaseDate:Date, releaseStatus:ReleaseStatus): FilmData
}

mutation InsertFilm($title:String!, $director:String, $releaseDate:Date, $releaseStatus:ReleaseStatus) {
  insert_film(title: $title, director: $director, releaseDate: $releaseDate, releaseStatus: $releaseStatus) { id }
}


```

Output Haxe:

```
/* - - - - Haxe / GraphQL compatibility types - - - - */
abstract IDString(String) to String from String {
  // Relaxed safety -- allow implicit fromString
//  TODO: optional strict safety -- require explicit fromString:
//  public static inline function fromString(s:String) return cast s;
//  public static inline function ofString(s:String) return cast s;
}
typedef ID = IDString;
typedef Boolean = Bool;
/* - - - - - - - - - - - - - - - - - - - - - - - - - */


/* Schema: */
typedef SchemaQueryType = MyQueries;
typedef SchemaMutationType = MyMutations;

/* scalar Date */
abstract Date(Dynamic) { }

@:enum abstract ReleaseStatus(String) {
  var PRE_PRODUCTION = "PRE_PRODUCTION";
  var IN_PRODUCTION = "IN_PRODUCTION";
  var RELEASED = "RELEASED";
}

typedef IHaveID = {
  id: ID
}

typedef FilmData = {
  id: ID,
  title: String,
  ?director: String,
  ?releaseDate: Date,
  ?releaseStatus: ReleaseStatus
}

typedef MyQueries = {
  ?film: Array<FilmData>
}

typedef MyMutations = {
  ?insert_film: FilmData
}

typedef Args_MyMutations_insert_film = {
  title: String,
  ?director: String,
  ?releaseDate: Date,
  ?releaseStatus: ReleaseStatus
}
/* Operation def: GetFilmsByDirector */
typedef OP_GetFilmsByDirector_Result = {
  ?film:Array<{ /* subset of FilmData */
    title:String,
    ?director:String,
    ?releaseDate:Date,
  }>,
}

typedef OP_GetFilmsByDirector_Vars = {
  ?director: String
}
/* Operation def: InsertFilm */
typedef OP_InsertFilm_Result = {
  ?insert_film:{ /* subset of FilmData */
    id:ID,
  },
}

typedef OP_InsertFilm_Vars = {
  title: String,
  ?director: String,
  ?releaseDate: Date,
  ?releaseStatus: ReleaseStatus
}
```
