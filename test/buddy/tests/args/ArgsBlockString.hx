package tests.args;

import buddy.*;
using buddy.Should;

class ArgsBlockString extends BuddySuite
{
  public static inline var gql = '

type SomeType {
  foo(blk_str1: String = """
                Does it have leading white
                space? And do we parse it properly?
"""
):String
}

';

  public function new() {
    describe("ArgsBlockString: The Parser and HaxeGenerator", {

      var parser:graphql.parser.Parser;

      it('should parse the document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 1 definition from this schema", {
        parser.document.definitions.length.should.be(1);
      });

      it("should parse the block string (removing leading spaces) correctly", {
        var doc:Dynamic = parser.document;
        var val:String = doc.definitions[0].fields[0].arguments[0].defaultValue.value;
        val.should.be("Does it have leading white\nspace? And do we parse it properly?");
      });
     
    });
  }

}

