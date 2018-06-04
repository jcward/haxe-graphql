package;

class Test
{
  public static function main()
  {
    test('StarWarsTest.gql');
    // test('basic_schema.gql');
    // test('basic_types.gql');
    // test('args_no_values.gql');
    // test('arguments.gql');
    //test('schema-kitchen-sink.graphql');
  }

  private static function test(fn)
  {
    trace('============================================================');
    trace('============================================================');
    trace('============================================================');
    trace('=== Loading from: ${ fn }');
    trace('============================================================');
    trace('============================================================');
    trace('============================================================');
    var source = sys.io.File.getContent(fn);

    var p = new graphql.parser.Parser(source);
    trace(source);

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
