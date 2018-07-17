package tests.fragments;

import buddy.*;
using buddy.Should;

class Unreachable extends BuddySuite
{
  public static inline var gql = '
type Human {
  human_id:ID!
  name:String!
}

type Droid {
  droid_id:ID!
  name:String!
}

type Query {
  human_by_id(id:ID!): Human
}

query HumanById($$id:ID!) {
  human_by_id(id: $$id) {
    human_id
    name
    ... on Human {
      name
      ... on Droid {
        # This condition is never reachable, because there is no relationship
        # that allows constraints Human and then Droid. Will error in generator.
        unreachable_field
      }
    }
  }
}
';

  public function new() {
    describe("fragments.Unreachable test: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the test document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should error about the unreachable field...", {
        var err = graphql.HaxeGenerator.parse.bind(parser.document).should.throwType(String);
        err.should.contain('specified field unreachable_field that didn\'t get used');
        err.should.contain('in possible types [Human]');
        err.should.contain('via constraints [Human, Droid]');
      });


    });
  }

}

