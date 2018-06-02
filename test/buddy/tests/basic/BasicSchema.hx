package tests.basic;

import buddy.*;
using buddy.Should;

class BasicSchema extends BuddySuite
{

  public static inline var gql = '

scalar Date

enum Greetings {
  Hello
  Hi
  Salutations
}

interface INamed {
  name : String!
}

type Person implements INamed {
  id:    ID!
  name : String!
  friends: [Person!]
  birthday: Date
}

type Dog implements INamed {
  id:    ID!
  name : String!
}

';

  public function new() {
    describe("BasicSchema: The Parser and HaxeGenerator", {

      var parser:graphql.parser.Parser;
      var haxe:String;

      beforeAll(function() {
        parser = new graphql.parser.Parser(gql);
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe = result.stdout;
      });

      it("should parse 5 definitions from this basic schema", {
        parser.document.definitions.length.should.be(5);
      });

      it("should generate the expected Haxe code", {
        haxe.should.contain('typedef Person');
        haxe.should.contain('typedef Dog');
        haxe.should.contain('typedef INamed');
        haxe.should.contain('abstract Date');
        haxe.should.contain('enum Greetings');
        haxe.should.contain('Salutations;');
      });

      it("should generate proper optional typedef fields", {
        haxe.should.contain('id:');
        haxe.should.not.contain('?id:');
        haxe.should.contain('?birthday:');
        haxe.should.contain('?friends:');
        haxe.should.not.contain('?name:');
      });

    });
  }
}
