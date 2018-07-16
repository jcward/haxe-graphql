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

scalar Location

interface Character {
  character_id:ID!
  age:Int!
}

type Droid implements Character & HasName & HasAge {
  character_id:ID!
  droid_id:ID!
  name:String!
  age:Int!
  bot_type:String!
}

type Human implements Character & HasName & HasAge {
  character_id:ID!
  human_id:ID!
  name:String!
  age:Int!
  hair_color:String
  vision_20:Int
}

type Anon implements Character {
  character_id:ID!
  anon_id:ID!
  age:Int!
  location:Location
}

interface HasName {
  name:String!
}

interface HasAge {
  age:Int!
}

type Query {
  character_by_name(name:String!): HasName
#  character_by_id(id:ID!): Character
  human_by_id(id:ID!): Human
}

query CharacterByName($$name:String!) {
  character_by_name(name: $$name) {
    name
    ... on Human { vision_20 ...HumanImportantDetails }
    ... on Droid { ...DroidImportantDetails }
 
    # No anons here, by_name
 
    ... on HasAge { age } # This will matter as the base doesnt (cant) implement HasAge
  }
}
 
# query CharacterByID($$id:ID!) {
#   character_by_id(id: $$id) {
#     character_id
#     age
#     ... on Human { name vision_20 ...HumanImportantDetails }
#     ... on Droid { name ...DroidImportantDetails }
#     ... on Anon  { location }
#  
#     ... on HasAge { age } # This will matter as the base doesnt (cant) implement HasAge
#   }
# }

query HumanById($$id:ID!) {
  human_by_id(id: $$id) {
    human_id
    character_id
    name

    # This will get subsumed into the base fields, as Human implements HasAge,
    # so, no extra _as_HasAge type will be generated
    ... on HasAge { age }

    # These will get subsumed into the base fields, as Human is Human,
    # so, no extra _as_Human type will be generated
    ... on Human { vision_20 }
    ...HumanImportantDetails # Simple DRY usage

    # What if we specified ...on Droid -- perhaps a warning, because
    # the schema makes no allownace for a relationship between the
    # Human & Droid types. Though technically not an error, as the
    # underlying language may allow such a construct (e.g. dynamic Android)

    # Nobody said they arent inane, right?
    ... on Human {
      name
      ... on Human { # Actually, you can alias in here...
        a_vision_score: vision_20
        ... on Human {
          human_id
          ... on Human {
            hair_color
          }
        }
      }
    }

    # Excellent, this gives the expected error:
    # ... on Human {
    #   ... on Droid { # impossible / unreachable via the schema...
    #     droid_id
    #   }
    # }

  }
}

fragment HumanImportantDetails on Human {
  human_id
  age
  hair_color
}

fragment DroidImportantDetails on Droid {
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
