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

type Query {
  by_title(title:String!): [FilmData]
}

type FilmData {
  id: ID!
  title: String
  related_films: [ID]
  tag_list: [String]!
}

query FilmsByTitle($$title: String!) {
  by_title(title:$$title) {
    id
    title
    related_films
    tag_list
  }
}

';

    // var td = 
    // var p = new haxe.macro.Printer();
    // trace(p.printTypeDefinition(td));
    trace(macro :Int);
    trace(macro :String);
    trace(macro :Array<String>);
    trace(macro :Test);

    var p = new haxe.macro.Printer();
    trace(p.printComplexType( macro :Array<Array<{ a:String, ?b:Int }>> ));

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
