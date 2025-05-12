package tests.issues;

import buddy.*;
using buddy.Should;

// Ensure that interfaces can implement (multiple) other interfaces
class Issue48 extends BuddySuite
{
  public static inline var gql = 
  '
interface Foo {
  foo: Int
}

interface Bar {
  bar: Int
}

# Duplication is mandatory. You cannot omit the inherited field list in the child interface.
interface Baz implements Foo {
  foo: Int
}

# Duplication is mandatory. You cannot omit the inherited field list in the child interface.
interface BazBar implements Foo & Bar {
  foo: Int
  bar: Int
}
  ';

  public function new() {
    describe("Issue48:", {

      var parser:graphql.parser.Parser;

      // Parser successfully generates Haxe code
      it('should parse this query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      // Haxe code has the expected definitions
      it("...and it should have the interface definitions...", {
        haxe_code.should.contain("typedef Foo =");
        haxe_code.should.contain("typedef Bar =");
        haxe_code.should.contain("typedef Baz =");
        haxe_code.should.contain("typedef BazBar =");
      });
    });

  }

}
