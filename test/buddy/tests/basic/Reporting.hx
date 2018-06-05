package tests.basic;

import buddy.*;
using buddy.Should;


class Reporting extends BuddySuite
{

  public static inline var gql = '

schema {
  query: Query
  mutation: Mutation
}

type Query {
  people:[Person]! ***
}

';

  public function new() {
    describe("Reporting: The Parser", {

      var parser:graphql.parser.Parser;
      var msg:String = null;
      var did_throw = false;

      it('should throw when it parses the document', {
        try {
          parser = new graphql.parser.Parser(gql);
        } catch (e:Dynamic) {
          msg = Std.string(e);
          did_throw = true;
        }

        did_throw.should.be(true);
      });

      it('should contain the correct error message...', {
        msg.should.contain("Error: Name identifier expected");
      });

      it('...on the correct line...', {
        msg.should.contain("Untitled:9:");
      });

      it('...at the correct starting character', {
        msg.should.contain("Untitled:9: characters 19");
      });

    });
  }
}
