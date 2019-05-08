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
           blk_str: String = """A block " "\" " quote!!""" ,
           str : String = "Hello World" ,
           e : ASCENDING ,
           obj: Person = { key:[ ASCENDING, 3.5e-3, false ], def:null },
           sort_order:SortType = DESCENDING ):[Person]
}

';

  public function new() {
    describe("ArgsDefaultValues: The Parser and HaxeGenerator", {

      var parser:graphql.parser.Parser;

      it('should parse the document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 3 definitions from this schema", {
        parser.document.definitions.length.should.be(2);
      });

      // This GQL will not generate, as it references types that don't exist
      it("should throw unknown type", {
          var err:String = graphql.HaxeGenerator.parse.bind(parser.document).should.throwType(String);
          err.should.contain("unknown type: Person");
      });

     
    });
  }

}

