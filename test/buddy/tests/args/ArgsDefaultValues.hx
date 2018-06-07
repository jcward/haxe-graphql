package tests.args;

import buddy.*;
using buddy.Should;

class ArgsDefaultValues extends BuddySuite
{
  public static inline var gql = '

enum SortType {
 ASCENDING
 DESCENDING
}

type SomeType {
  name:String!
  age:Int
  friends( named: [String] = ["default_joe", "default_suzie"],
           id: ID=null,
           has_id: Boolean = false,
## TODO: BlockString disabled... ##      blk_str: String = """A block " "\" " quote!!""" ,
           str : String = "Hello World" ,
           e : ASCENDING ,
           obj: Person = { "key":[ ASCENDING, 3.5e-3, false ], "def":null },
           sort_order:SortType = DESCENDING ):[Person]
}

';

  public function new() {
    describe("ArgsDefaultValues: The Parser and HaxeGenerator", {

      var parser:graphql.parser.Parser;
      var haxe:String;

      it('should parse the document without error', {
        parser = new graphql.parser.Parser(gql);
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe = result.stdout;
      });

      it("should parse 2 definitions from this schema", {
        parser.document.definitions.length.should.be(2);
      });

      it("generated haxe contain the expected args type", {
        haxe.should.contain('typedef Args_SomeType_friends');
      });

    });
  }

}

