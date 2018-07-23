package tests.issues;

import buddy.*;
using buddy.Should;

// Issue #31 - the order of fragment defitions should not throw.
class Issue31 extends BuddySuite
{

  public static inline var gql = '

type SomeData {
  id:ID!
  foo:String!
  bar:String!
}

type Query {
  get_some_data: SomeData
}

query GetSomeData {
  get_some_data {
    id
    ...OuterFrag
  }
}

';

  public function new() {
    describe("Issue30:", {

      it('should parse and generate without error with outer definition first', {
        var parser = new graphql.parser.Parser(gql+'
fragment OuterFrag on SomeData {
  foo
  ...InnerFrag
}

fragment InnerFrag on SomeData {
  bar
}
');
        var code = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef Fragment_OuterFrag");
        code.should.contain("typedef Fragment_InnerFrag");
      });

      it('should parse and generate without error with inner definition first', {
        var parser = new graphql.parser.Parser(gql+'
fragment InnerFrag on SomeData {
  bar
}

fragment OuterFrag on SomeData {
  foo
  ...InnerFrag
}
');
        var code = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef Fragment_OuterFrag");
        code.should.contain("typedef Fragment_InnerFrag");
      });

    });
  }

}
