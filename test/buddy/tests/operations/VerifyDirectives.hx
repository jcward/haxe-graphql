package tests.operations;

import buddy.*;
using buddy.Should;

class VerifyDirectives extends BuddySuite
{

  public static inline var common_gql = '

# Creates typedefs for all schema types

type FooData {
  foo_id:ID!
}

type BarData {
  bar_id:ID!
}

union SomeData = FooData | BarData

type OuterData {
  id:ID!
  title:String!
  description:String
  foo_or_bar_data: SomeData!
}

type Query {
  get_content_by_id: OuterData
}

';

  public function new() {
    describe("VerifyDirectives:", {

      it('should validate these directives without error', {
        var parser = new graphql.parser.Parser(common_gql+'

fragment InnerFrag on OuterData {
  foo_or_bar_data @include(if: $$with_data) {
    ...on FooData {
      common_id: foo_id
    }
    ...on BarData {
      common_id: bar_id
    }
  }
}

query GetContentsByID($$id: ID, $$with_data: Boolean=false) {
  get_content_by_id(id: $$id) {
    title
    description
    foo_or_bar_data @include(if: $$with_data) {
      ...on FooData {
        foo_id
      }
    }
    ...InnerFrag
  }
}

');

        var result = graphql.HaxeGenerator.parse(parser.document).stdout;
        result.should.contain("typedef OP_GetContentsByID_Result");
      });



      it('should throw on a query directive typo', {
        var parser = new graphql.parser.Parser(common_gql+'

fragment InnerFrag on OuterData {
  foo_or_bar_data @include(if: $$with_data) {
    ...on FooData {
      common_id: foo_id
    }
    ...on BarData {
      common_id: bar_id
    }
  }
}

query GetContentsByID($$id: ID, $$with_data: Boolean=false) {
  get_content_by_id(id: $$id) {
    title
    description
    foo_or_bar_data @include(if: $$with_a_typo) {
      ...on FooData {
        foo_id
      }
    }
    ...InnerFrag
  }
}

');

        var err = graphql.HaxeGenerator.parse.bind(parser.document).should.throwType(String);
        err.should.contain("operation GetContentsByID is expecting parameter with_a_typo");
      });


      it('should throw on a fragment directive typo', {
        var parser = new graphql.parser.Parser(common_gql+'

fragment InnerFrag on OuterData {
  foo_or_bar_data @include(if: $$with_frag_typo) {
    ...on FooData {
      common_id: foo_id
    }
    ...on BarData {
      common_id: bar_id
    }
  }
}

query GetContentsByID($$id: ID, $$with_data: Boolean=false) {
  get_content_by_id(id: $$id) {
    title
    description
    foo_or_bar_data @include(if: $$with_data) {
      ...on FooData {
        foo_id
      }
    }
    ...InnerFrag
  }
}

');

        var err = graphql.HaxeGenerator.parse.bind(parser.document).should.throwType(String);
        err.should.contain("operation GetContentsByID is expecting parameter with_frag_typo");
      });

    });
  }

}
