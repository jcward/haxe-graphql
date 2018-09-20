package tests.issues;

import buddy.*;
using buddy.Should;

class Issue35 extends BuddySuite
{

  public static inline var gql = '
type Foo {
  age: Int
  name: String
  stars: InvalidTypeTypo
}

type Query {
  get_invalid: Foo
}

query GetInvalidTypedField {
  get_invalid {
    name
    stars
  }
}
    ';

  public function new() {
    describe("UnnamedQuery: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the unnamed query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("But... the HaxeGenerator should report both errors (unknown type, and query referencing unknown type)", {
        try {
          var result = graphql.HaxeGenerator.parse(parser.document);
          "OH NO".should.contain("IT SHOULD HAVE THROWN");
        } catch (e:Dynamic) {
          Std.string(e).should.contain("Error: unknown type: InvalidTypeTypo");
          Std.string(e).should.contain("Error processing operation GetInvalidTypedField: Error: type not found: InvalidTypeTypo");
        }
      });

      it("And we should be able to tell HaxeGenerator not to throw, rather just give us stderr", {
        var result = graphql.HaxeGenerator.parse(parser.document, null, false);
        result.stdout.should.be("");
        result.stderr.should.contain("Error: unknown type: InvalidTypeTypo");
        result.stderr.should.contain("Error processing operation GetInvalidTypedField: Error: type not found: InvalidTypeTypo");
      });

    });

  }

}
