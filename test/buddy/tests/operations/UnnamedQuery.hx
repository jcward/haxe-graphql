package tests.operations;

import buddy.*;
using buddy.Should;

class UnnamedQuery extends BuddySuite
{

  public static inline var gql = '
    {
      title
      id
    }
    ';

  public function new() {
    describe("UnnamedQuery: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the unnamed query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 1 definitions and 2 selections from this schema", {
        parser.document.definitions.length.should.be(1);
        var d:Dynamic = parser.document.definitions[0];
        d.selectionSet.selections.length.should.be(2);
      });


      var haxe:String;
      it("But... the HaxeGenerator should throw -- only named operations are supported...", {
        try {
          var result = graphql.HaxeGenerator.parse(parser.document);
          haxe = result.stdout;
          "OH NO".should.contain("IT DIDN'T THROW");
        } catch (e:Dynamic) {
          Std.string(e).should.contain("Only named operations are supported...");
        }
      });

    });

  }

}

