package tests.issues;

import buddy.*;
using buddy.Should;

// allow selection on union types (via fragments)
//  - I believe we aren't required to specify a fragment for every case. Currently
//    will return empty types for unselected union members.
class Issue30 extends BuddySuite
{

  public static inline var gql = '

# Creates typedefs for all schema types

type FooContent {
  foo_id:ID!
}

type BarContent {
  bar_id:ID!
}

union ExtContentData = FooContent | BarContent

type ContentData {
  id:ID!
  title:String!
  description:String
  ext_content_data: ExtContentData!
}

type Query {
  get_content_by_id: ContentData
}

query GetContentsByID($$id: ID) {
  get_content_by_id(id: $$id) {
    title
    description
    ext_content_data {
      ...on FooContent {
        foo_id
      }
    }
  }
}

';

  public function new() {
    describe("Issue30:", {

      var parser:graphql.parser.Parser;

      it('should parse this query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
        Main.print(haxe_code);
      });

      it("...and the OP_GetContentsByID_InnerResult__ext_content_data, should exist...", {
        var result = Main.find_type_in_code(haxe_code, 'abstract OP_GetContentsByID_InnerResult__ext_content_data(Dynamic) {');
        Main.print(result, Main.Color.RED);
        result.split(':from').length.should.be(3);
      });
    });
  }

}
