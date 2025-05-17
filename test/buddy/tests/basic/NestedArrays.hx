package tests.basic;

import buddy.*;
using buddy.Should;

// Ensure that nested arrays like [[Int]] are properly converted to Array<Array<Int>> in Haxe
class NestedArrays extends BuddySuite
{
  public static inline var gql = 
  '
type NestedArrays {
  # Single array
  singleArray: [Int]
  # Double nested array
  doubleArray: [[Int]]
  # Triple nested array
  tripleArray: [[[Int]]]
  # Nullable double nested array
  nonNullableDoubleArray: [[Int]!]!
}
  ';

  public function new() {
    describe("NestedArrays:", {

      var parser:graphql.parser.Parser;

      // Parser successfully generates Haxe code
      it('should parse this document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      // Haxe code has the expected definitions
      it("...and it should have properly nested array types", {
        haxe_code.should.contain("?singleArray : Array<Int>");
        haxe_code.should.contain("?doubleArray : Array<Array<Int>>");
        haxe_code.should.contain("?tripleArray : Array<Array<Array<Int>>>");
        haxe_code.should.contain("nonNullableDoubleArray : Array<Array<Int>>");
      });
    });
  }
} 
