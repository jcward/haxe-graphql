package tests.operations;

import buddy.*;
using buddy.Should;

class QueryTypeGeneration extends BuddySuite
{
  // TODO: directives:  content @include(if: $include_content) {

  public static inline var gql = '

schema {
  query: FooBarQuery
}

scalar Date

type Director {
  name: String!
  age:Int!
}

type FilmData {
  title:ID!
  director:Director
  releaseDate:Date
}

type FooBarQuery {
  film: [FilmData]
}

query GetReturnOfTheJedi($$id: ID) {
  film(id: $$id) {
    title
    director {
      name
      age
    }
    releaseDate
  }
}

';

  public function new() {
    describe("QueryTypeGeneration: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the ARGS query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 6 definitions from this schema", {
        parser.document.definitions.length.should.be(6);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      it("...and the query type should be present...", {
        haxe_code.should.contain("typedef QueryResult_GetReturnOfTheJedi");
      });

      var type_of_getReturnOfTheJediQuery:String = "";
      it("...and it should have correct types, arrays, and optionality.", {
          var capture = false;
          for (line in haxe_code.split("\n")) {
            if (line.indexOf('typedef QueryResult_GetReturnOfTheJedi')>=0) capture = true;
            if (capture) type_of_getReturnOfTheJediQuery += line + "\n";
          }

          type_of_getReturnOfTheJediQuery.should.contain('?film:Array');
          type_of_getReturnOfTheJediQuery.should.contain('title:ID');
          type_of_getReturnOfTheJediQuery.should.not.contain('?title:ID');
          type_of_getReturnOfTheJediQuery.should.contain('?director:{');
          type_of_getReturnOfTheJediQuery.should.contain('?releaseDate:Date');
      });



      it("We can be write to /tmp/QueryGen.hx...", function() {
        var exec_code = '
        class QueryGen {
          public static function main() {
            var q:QueryResult_GetReturnOfTheJedi = null;
            $$type(q.film[0]);         // prints type to stderr
            trace("and we executed");  // prints to stdout
          }
        }
        ' + haxe_code;

        sys.io.File.saveContent('/tmp/QueryGen.hx', exec_code);
      });

      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      it("...and the code will output the film type on stderr Haxe compiler!", function() {
        var p = new sys.io.Process("haxe", ["--cwd", "/tmp", "-x", "QueryGen"]);
        var stdout = p.stdout.readAll().toString();
        var stderr = p.stderr.readAll().toString();
        stderr.should.contain('?releaseDate : Null<Date>');
        stdout.should.contain('and we executed');
      });

    });
  }

}

