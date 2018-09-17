package tests.basic;

import buddy.*;
using buddy.Should;

class BasicErrors extends BuddySuite
{

  public function new() {
    describe("BasicErrors:", {


      it("a type cannot define a field more than once", {
        var parser:graphql.parser.Parser = new graphql.parser.Parser('
type Oops {
  foo:String
  foo:String
}
');
        try {
          var code = graphql.HaxeGenerator.parse(parser.document).stdout;
          "OH NO".should.contain("IT DIDN'T THROW");
        } catch (e:Dynamic) {
          Std.string(e).should.contain("type Oops defines field foo more than once");
        }
      });


    });

  }

}

