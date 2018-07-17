package tests.fragments;

import buddy.*;
using buddy.Should;

class EmptyFragment extends BuddySuite
{
  public static inline var gql = '
type Human {
  human_id:ID!
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
      # An empty fragment will fail in the parser with "Expected Name, found }"
    }
  }
}
';

  public function new() {
    describe("fragments.EmptyFragment test: The Parser", {

      function parse() {
        new graphql.parser.Parser(gql);
      }

      it('should fail to parse, because the fragment made no selections', {
        var err:String = parse.bind().should.throwType(String);
        err.should.contain('Expected Name, found }');
      });


    });
  }

}

