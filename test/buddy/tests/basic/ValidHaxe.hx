package tests.basic;

import buddy.*;
using buddy.Should;

class ValidHaxe extends BuddySuite
{

  public function new() {
    describe("ValidHaxe: The Parser and HaxeGenerator", {

      var parser:graphql.parser.Parser;
      var haxe:String;

      it("should generate haxe code...", function() {
        parser = new graphql.parser.Parser(BasicTypes.gql);
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe = result.stdout;
      });

      it("...that can be written to /tmp/Test.hx...", function() {
        var exec_code = '
        class Test {
          public static function main() {
            var dog = { "name":"woof", id:"abc123" };
            trace(\'hello buddy, my name is $${ dog.name }\');
          }
        }
        ' + haxe;

        sys.io.File.saveContent('/tmp/Test.hx', exec_code);
      });

      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      it("...and the code, if it's valid, will be executed by the Haxe compiler!", function() {
        var output = new sys.io.Process("haxe", ["--cwd", "/tmp", "-x", "Test"]).stdout.readAll().toString();
        output.should.contain('my name is woof');
      });

    });
  }
}
