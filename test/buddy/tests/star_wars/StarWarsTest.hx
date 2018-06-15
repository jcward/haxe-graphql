package tests.star_wars;

import buddy.*;
using buddy.Should;

class StarWarsTest extends BuddySuite
{

  public function new() {
    describe("StarWarsTest: The Parser and HaxeGenerator", {

      var source:String;
      var parser:graphql.parser.Parser;
      var haxe:String;

      it("can read the StarWarsTest.gql...", {
        source = sys.io.File.getContent('tests/star_wars/StarWarsTest.gql');
        source.should.contain('type Starship');
        source.should.contain('union SearchResult');
      });

      it("...and parse it...", {
        parser = new graphql.parser.Parser(source);
      });

      it("...and generate Haxe from it...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe = result.stdout;
      });

      it("...and the Haxe code has the expected types...", {
        haxe.should.contain('typedef Character');
        haxe.should.contain('@:enum abstract LengthUnit');
        haxe.should.contain('typedef Human');
        haxe.should.contain('typedef Droid');
        haxe.should.contain('typedef Args_Droid_friendsConnection');
        haxe.should.contain('typedef FriendsEdge');
        haxe.should.contain('typedef Args_Starship_length');
      });

      it("...and can be written to /tmp/StarWars.hx...", function() {
        var exec_code = '
        class StarWars {
          public static function main() {
            var luke = { "name":"Luke", id:"abc123", friends:[], appearsIn:[  NEWHOPE, EMPIRE, JEDI ] };
            trace(\'Use the force, $${ luke }\');
            trace(\'And $${ luke.name } appears in $${ luke.appearsIn.length } episodes (known by the current schema)\');
          }
        }


        ' + haxe;

        sys.io.File.saveContent('/tmp/StarWars.hx', exec_code);
      });

      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      it("...and the code, if it's valid, will be executed by the Haxe compiler!", function() {
        var output = new sys.io.Process("haxe", ["--cwd", "/tmp", "-x", "StarWars"]).stdout.readAll().toString();
        output.should.contain('Luke appears in 3 episodes');
      });

    });
  }
}
