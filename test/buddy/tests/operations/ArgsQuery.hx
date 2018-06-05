package tests.operations;

import buddy.*;
using buddy.Should;

class ArgsQuery extends BuddySuite
{
  // TODO: directives:  content @include(if: $include_content) {

  public static inline var gql = '
query GetReturnOfTheJedi($$id: ID) {
  film(id: $$id) {
    title
    director
    releaseDate
  }
}';

  public function new() {
    describe("ArgsQuery: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the ARGS query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 1 definitions and 6 selections from this schema", {
        parser.document.definitions.length.should.be(1);

        parser.document.definitions[0].selectionSet.selections.length.should.be(1);
      });

      var haxe:String;
      it("The HaxeGenerator should then generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe = result.stdout;
      });

    });
  }

}

