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

schema {
  mutation: MyMutations
}

interface HasName {
  name:String!
}

union Being = Person | Dog

interface Job {
  title:String!
}

type Plumber implements Job {
  title:String!
  plumber_id:ID!
}

type Person implements HasName {
  person_id:ID!
  name:String!
  job:Job
}

type Dog implements HasName {
  dog_id:ID!
  name:String!
}

# - - Mutations - -

type MyMutations {
  insert_person(person:Person!): Person
}

input JobInput {
  title:String!
}

input PersonInput {
  person_id:ID!
  name:String!
  job:JobInput
}

mutation InsertPerson($$input: PersonInput!) {
  insert_person(input: $$input) { person { id } }
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
