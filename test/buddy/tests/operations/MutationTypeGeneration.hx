package tests.operations;

import buddy.*;
using buddy.Should;

class MutationTypeGeneration extends BuddySuite
{
  // TODO: directives:  content @include(if: $include_content) {

  public static inline var gql = '

schema {
  query: MyQueries
  mutation: MyMutations
}

scalar Date

enum ReleaseStatus {
  PRE_PRODUCTION
  IN_PRODUCTION
  RELEASED
}

interface IHaveID {
  id:ID!
}

type FilmData implements IHaveID {
  id:ID!
  title:String!
  director:String
  releaseDate:Date
  releaseStatus:ReleaseStatus
}

# - Queries - -
type MyQueries {
  film: [FilmData]
}

# Creates query response typedefs
query GetFilmsByDirector($$director: String) {
  film(director: $$director) {
    title
    director
    releaseDate
  }
}

# - Mutations - -
type MyMutations {
  insert_film(title:String!, director:String, releaseDate:Date, releaseStatus:ReleaseStatus): FilmData
}

mutation InsertFilm($$title:String!, $$director:String, $$releaseDate:Date, $$releaseStatus:ReleaseStatus) {
  insert_film(title: $$title, director: $$director, releaseDate: $$releaseDate, releaseStatus: $$releaseStatus) { id }
}

';

  public function new() {
    describe("MutationTypeGeneration: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the schema without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 9 definitions from this schema", {
        parser.document.definitions.length.should.be(9);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      it("...and the mutation result and vars types should be present...", {
        haxe_code.should.contain("typedef OP_InsertFilm_Result");
        haxe_code.should.contain('typedef OP_InsertFilm_Vars');
      });

      var result_type_of_insertFilm:String = "";
      it("...and the result type should have correct types, arrays, and optionality.", {
        var capture = false;
        for (line in haxe_code.split("\n")) {
          if (line.indexOf('typedef OP_InsertFilm_Result')>=0) capture = true;
          if (capture==true && line=='}') capture = false;
          if (capture) result_type_of_insertFilm += line + "\n";
        }

        // result type:
        result_type_of_insertFilm.should.contain('?insert_film:');
        result_type_of_insertFilm.should.contain('id:ID');
        result_type_of_insertFilm.should.not.contain('?id:ID');
      });

      var vars_type_of_insertFilm:String = "";
      it("...and the vars type should have correct types and optionality.", {
        var capture = false;
        for (line in haxe_code.split("\n")) {
          if (line.indexOf('typedef OP_InsertFilm_Vars')>=0) capture = true;
          if (capture) vars_type_of_insertFilm += line + "\n";
          if (capture==true && line=='}') capture = false;
        }

        // vars type:
        vars_type_of_insertFilm.should.contain('title: String');
        vars_type_of_insertFilm.should.contain('?director: String');
        vars_type_of_insertFilm.should.contain('?releaseDate: Date');
        vars_type_of_insertFilm.should.contain('?releaseStatus: ReleaseStatus');
      });


      it("We can be write to /tmp/MutationGen.hx...", function() {
        var exec_code = '
        class MutationGen {
          public static function main() {
            var q:OP_InsertFilm_Result = null;
            $$type(q.insert_film);     // prints type to stderr
            trace("and we executed");  // prints to stdout
          }
        }
        ' + haxe_code;

        sys.io.File.saveContent('/tmp/MutationGen.hx', exec_code);
      });

      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      it("...and the code will output the film type on stderr Haxe compiler!", function() {
        var p = new sys.io.Process("haxe", ["--cwd", "/tmp", "-x", "MutationGen"]);
        var stdout = p.stdout.readAll().toString();
        var stderr = p.stderr.readAll().toString();
        stderr.should.contain('Warning : Null<{ id : ID }>');
        stdout.should.contain('and we executed');
      });

    });
  }

}

