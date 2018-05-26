package;

class Test
{
  public static function main()
  {
    test('basic.gql');
    test('schema-kitchen-sink.graphql');
  }

  private static function test(fn)
  {
    trace('\n\n= = = = = = = = = = =\nLoading $fn\n= = = = = = = = = = =');
    var source = sys.io.File.getContent(fn);

    var p = new graphql.parser.Parser(source);
    trace('Parsed document:');
    trace(source);

    trace('Generating Haxe:');
    trace(graphql.HaxeGenerator.parse(p.document));
  }
}