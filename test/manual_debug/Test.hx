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


extend type SomeData {
  bar: Int!
}

extend type Query {
  get_some_data_with_bar: SomeData
}

query GetSomeDataWithBar {
  get_some_data_with_bar {
    id
    foo
    bar
  }
}



type SomeData {
  id:ID!
  foo:String!
}

type Query {
  get_some_data: SomeData
}

query GetSomeData {
  get_some_data {
    id
    foo
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Assume another file has been concatenated and extends SomeData
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
