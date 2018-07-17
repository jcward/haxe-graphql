package tests.basic;

import buddy.*;
using buddy.Should;

class BasicSchema extends BuddySuite
{

  public static inline var gql = '

schema {
  query: Query
  mutation: Mutation
}

type Query {
  people:[Person]!
}

type Mutation {
  insert(p:Person):InsertResult
}

enum InsertResult {
  Foo
  Bar
}

type Person {
  id:    ID!
  name : String!
  friends: [Person!]
}

';

  public function new() {
    describe("BasicSchema: The Parser and HaxeGenerator", {

      var parser:graphql.parser.Parser;
      var haxe:String;

      it('should parse the document without error', {
        parser = new graphql.parser.Parser(gql);
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe = result.stdout;
      });

      it("should parse 5 definitions from this basic schema", {
        parser.document.definitions.length.should.be(5);
      });

      // Hmm, not I'm questioning whether we want / need these...
      // it("should generate the expected schema aliases", {
      //   haxe.should.contain('typedef SchemaQueryType = Query');
      //   haxe.should.contain('typedef SchemaMutationType = Mutation');
      // });

      it("should generate the basic type signatures", {
        haxe.should.contain('typedef Query');
        haxe.should.contain('typedef Mutation');
        haxe.should.contain('typedef Person');
        haxe.should.contain('@:enum abstract InsertResult');
      });

      it("should generate an arg type for mutation insert", {
        haxe.should.contain('typedef Args_Mutation__insert');
      });

    });
  }
}
