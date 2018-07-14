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

type Query {
  by_name(name:String!): HasName
}

query ByName($$name:String!) {
  by_name(name: $$name) {
    name

    ... on Person {
      ...PersonDetails
 
      job {
        title
        ... on Plumber {
          plumber_id
          ...PlumberDetails
        }
      }
    }
 
    ... on Dog {
      dog_id
    }

  }
}


## TODO: Named fragment (DRY)
fragment PersonDetails on Person {
  person_id
}

fragment PlumberDetails on Plumber {
  plumber_id
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
