package tests.operations;

import buddy.*;
using buddy.Should;

class BasicQuery extends BuddySuite
{
  // TODO: directives:  content @include(if: $include_content) {

  public static inline var gql = '
query AQuery {
  title
  id
  course_id
  content {
    id
  }
  unlock_at
  submissions {
    id
  }
}
';

  public function new() {
    describe("BasicQuery: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the BASIC query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 1 definitions and 6 selections from this schema", {
        parser.document.definitions.length.should.be(1);

        var d:Dynamic = parser.document.definitions[0];
        d.selectionSet.selections.length.should.be(6);
      });


      var haxe:String;
      it("The HaxeGenerator should then generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe = result.stdout;
      });

      it("...DARN, the query results are just dynamic for now :cry:", {
          haxe.should.contain("AQuery_Result = Dynamic");
      });

    });

  }

}

