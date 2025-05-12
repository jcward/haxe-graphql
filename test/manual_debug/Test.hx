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

    var gql = haxe.Resource.getString('injected_gql');
    if (gql==null || gql.length < 5) throw 'No GQL resource found';
    var p = new graphql.parser.Parser(gql, { noLocation:true });
    trace(gql);
    trace(p.document);

    trace('============================================================');
    trace('Generating Haxe:');
    trace('============================================================');
    try {
      var result = graphql.HaxeGenerator.parse(p.document);
      if (result.stderr.length>0) {
        trace('Error:\n${ result.stderr }');
      } else {
        trace(result.stdout);
      }
    } catch (e:Dynamic) {
      trace('Error parsing:');
      trace(e);
    }
    trace('============================================================');
    trace('============================================================');
    trace('============================================================\n\n');

  }
}
