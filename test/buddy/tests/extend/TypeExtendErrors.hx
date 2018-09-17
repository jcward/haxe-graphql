package tests.extend;

import buddy.*;
using buddy.Should;

class TypeExtendErrors extends BuddySuite
{

  public function new() {
    describe("TypeExtendErrors:", {

      it("should not find the base type", {
        var parser:graphql.parser.Parser = new graphql.parser.Parser('
type Base { id:ID! }
extend type Base { name:String }
extend type Base__Typo { age:Int }
');
        try {
          var code = graphql.HaxeGenerator.parse(parser.document).stdout;
          "OH NO".should.contain("IT DIDN'T THROW");
        } catch (e:Dynamic) {
          Std.string(e).should.contain("Type extension for Base__Typo didn't find base type");
        }
      });

      it("cannot overwrite an existing field (same type doesn't matter)", {
        var parser:graphql.parser.Parser = new graphql.parser.Parser('
type Base { id:ID! }
extend type Base { id:ID! }
');
        try {
          var code = graphql.HaxeGenerator.parse(parser.document).stdout;
          "OH NO".should.contain("IT DIDN'T THROW");
        } catch (e:Dynamic) {
          Std.string(e).should.contain("type Base defines field id more than once");
        }
      });

      it("cannot overwrite an existing field (of other extension)", {
        var parser:graphql.parser.Parser = new graphql.parser.Parser('
type Base { id:ID! }
extend type Base { foo:String }
extend type Base { foo:String }
');
        try {
          var code = graphql.HaxeGenerator.parse(parser.document).stdout;
          "OH NO".should.contain("IT DIDN'T THROW");
        } catch (e:Dynamic) {
          Std.string(e).should.contain("type Base defines field foo more than once");
        }
      });

    });

  }

}

