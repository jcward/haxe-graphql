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

type FooContent {
  foo_id:ID!
}

type BarContent {
  bar_id:ID!
}

union SomeData = FooContent | BarContent

type OuterData {
  id:ID!
  title:String!
  description:String
  foo_or_bar_data: SomeData!
}

type Query {
  get_content_by_id: OuterData
}

fragment InnerFrag on OuterData {
  foo_or_bar_data @include(if: $$with_data) {
    ...on FooContent {
      common_id: foo_id
    }
    ...on BarContent {
      common_id: bar_id
    }
  }
}

query GetContentsByID($$id: ID, $$with_data: Boolean=false) {
  get_content_by_id(id: $$id) {
    title
    description
    foo_or_bar_data @include(if: $$with_data) {
      ...on FooContent {
        foo_id
      }
    }
    ...InnerFrag
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
