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

interface Character {
  character_id:ID!
  name:String!
  age:Int!
}

type Droid implements Character & HasName {
  character_id:ID!
  droid_id:ID!
  name:String!
  age:Int!
  bot_type:String!
}

type Human implements Character & HasName {
  character_id:ID!
  human_id:ID!
  name:String!
  age:Int!
  hair_color:String
  vision_20:Int
}

interface HasName {
  name:String!
}

type Query {
  character_by_name(name:String!): HasName
  character_by_id(id:ID!): Character
}

query CharacterByName($$name:String!) {
  character_by_name(name: $$name) {
    name
    ... on Human { ...HumanDetails }
    ... on Droid { ...DroidDetails }
  }
}

query CharacterByID($$id:ID!) {
  character_by_id(id: $$id) {
    character_id
    name
    age
    ... on Human { ...HumanDetails }
    ... on Droid { ...DroidDetails }
  }
}

fragment HumanDetails on Human {
  human_id
  age
  hair_color
  vision_20
}

fragment DroidDetails on Droid {
  character_id
  droid_id
  age
  bot_type
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
