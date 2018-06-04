package;

class Test
{
  public static function main()
  {
    // test('StarWarsTest.gql');
    test('basic_schema.gql');
    // test('basic_types.gql');
    // test('args_no_values.gql');
    // test('arguments.gql');
    //test('schema-kitchen-sink.graphql');
  }

  private static function test(fn)
  {
    trace('\n\n= = = = = = = = = = =\nLoading $fn\n= = = = = = = = = = =');
    var source = sys.io.File.getContent(fn);

    var p = new graphql.parser.Parser(source);
    trace('Parsed document:');
    trace(source);

    trace('Generating Haxe:');
    var result = graphql.HaxeGenerator.parse(p.document);
    if (result.stderr.length>0) {
      trace('Error:\n${ result.stderr }');
    } else {
      trace(result.stdout);
    }
  }
}
