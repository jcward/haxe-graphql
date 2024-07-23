package;
import sys.io.File;
//import Playground;

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

    // Idea is to return the SDL Union as a Haxe Enum
    // var pm = ContentModule.OnPollModule({content_type:POLL, poll_id:'1234'});
    // var tm = ContentModule.OnTasklistModule({content_type:TASKLIST,tasklist_id: '1234'});
    // var cm = SagaAPICMSClient.GetContentModuleById(/*..*/);
    // switch (cm) {
    //   case ContentModule.OnPollModule({content_type:POLL, poll_id:'1234'}):
    //     trace('poll');
    //   case ContentModule.OnTasklistModule({content_type:TASKLIST,tasklist_id: '1234'}):
    //     trace('tasklist');
    //   default:
    //     trace('default');
    // }

    trace('============================================================');
    trace('============================================================');
    trace('============================================================');
    trace('Using literal source...');
    trace('============================================================');
    trace('============================================================');
    trace('============================================================');

    var gql = haxe.Resource.getString('injected_gql');
    var p = new graphql.parser.Parser(gql, { noLocation:true });
    trace(gql);
    trace(p.document);

    trace('============================================================');
    trace('Generating Haxe:');
    trace('============================================================');
    var result = graphql.HaxeGenerator.parse(p.document);
    if (result.stderr.length>0) {
      trace('Error:\n${ result.stderr }');
    } else {
      File.saveContent("GeneratedHaxe.hx", cast result.stdout);
      trace(result.stdout);
    }
    trace('============================================================');
    trace('============================================================');
    trace('============================================================\n\n');

  }
}
