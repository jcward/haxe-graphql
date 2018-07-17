package tests.basic;

import buddy.*;
using buddy.Should;

class BoolTest extends BuddySuite
{
  public function new() {
    describe("BoolTest:", {

      var parser:graphql.parser.Parser;
      var haxe:String;

      it('a GQL Boolean will generate a Haxe Bool', {
        var parser = new graphql.parser.Parser('type Thing { is_foo: Boolean }');
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe = result.stdout;
        haxe.should.contain(': Bool');
        haxe.should.not.contain(': Boolean');
      });

      it('a GQL typo of Bool will throw', {
        var parser = new graphql.parser.Parser('type Thing { is_foo: Bool }');
        var err:String = graphql.HaxeGenerator.parse.bind(parser.document).should.throwType(String);
        err.should.contain('unknown type: Bool');
      });

      it('a GQL type can be called Bool, and it\'ll get transformed to not interfere with Haxe Bool', {
        var parser = new graphql.parser.Parser('
  type Thing { actual_boolean: Boolean }
  type Bool { field: String }
  type Other { fake_bool: Bool }
');
        haxe = graphql.HaxeGenerator.parse(parser.document).stdout;

        // Core type collision, must get renamed
        haxe.should.contain('typedef Bool__ =');
        haxe.should.not.contain('typedef Bool =');
        haxe.should.contain('actual_boolean : Bool,');
        haxe.should.contain('fake_bool : Bool__,');
        //Sys.println(haxe);
      });

    });
  }
}
