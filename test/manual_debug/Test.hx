package;

class Test
{
  public static function main()
  {
    // test('query.gql');
    // test('StarWarsTest.gql');
    // test('basic_schema.gql');
    // test('basic_types.gql');
    // test('args_no_values.gql');
    // test('arguments.gql');
    // test('schema-kitchen-sink.graphql');
    // var source = sys.io.File.getContent(fn);

    trace('============================================================');
    trace('============================================================');
    trace('============================================================');
    trace('Using literal source...');
    trace('============================================================');
    trace('============================================================');
    trace('============================================================');

    var source = '

# Creates typedefs for all schema types

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

# Creates query response typedefs

query GetFilmsByDirector($$director: String) {
  film(director: $$director) {
    title
    director
    releaseDate
  }
}



';

    var p = new graphql.parser.Parser(source, { noLocation:true });
    trace(source);
    trace(p.document);

    trace('============================================================');
    trace('Generating Haxe:');
    trace('============================================================');
    var result = graphql.HaxeGenerator.parse(p.document);
    if (result.stderr.length>0) {
      trace('Error:\n${ result.stderr }');
    } else {
      trace(result.stdout);
    }
    trace('============================================================');
    trace('============================================================');
    trace('============================================================\n\n');

  }
}
