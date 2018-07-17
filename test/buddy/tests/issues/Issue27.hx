package tests.issues;

import buddy.*;
using buddy.Should;

// ensure that the TAnon() fields retain proper optionality and array-ness
class Issue27 extends BuddySuite
{

  public static inline var gql = '

type Query {
  films_by_title(title:String!): [FilmData]
}

type FilmData {
  id: ID!
  title: String
  required_related_films: [FilmData]!
  optional_related_films: [FilmData]
  required_tag_list: [String]!
  optional_tag_list: [String]
}

query FilmsByTitle($$title: String!) {
  films_by_title(title:$$title) {
    id
    title
    required_related_films {
      id
      rrtl: required_tag_list
      rotl: optional_tag_list
    }
    optional_related_films {
      id
      ortl: required_tag_list
      ootl: optional_tag_list
    }
    required_tag_list
    optional_tag_list
  }
}
';

  public function new() {
    describe("Issue27:", {

      var parser:graphql.parser.Parser;

      it('should parse this query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      var type_OP_FilmsByTitle_InnerResult:String;
      it("...and the OP_FilmsByTitle_InnerResult should exist...", {
        type_OP_FilmsByTitle_InnerResult = Main.find_type_in_code(haxe_code, 'typedef OP_FilmsByTitle_InnerResult');
        type_OP_FilmsByTitle_InnerResult.split(':').length.should.be(13);
      });

      it("...and the OP_FilmsByTitle_InnerResult should contain proper required fields...", {
        type_OP_FilmsByTitle_InnerResult.should.contain("required_related_films : Array");
        type_OP_FilmsByTitle_InnerResult.should.not.contain("?required_related_films : Array");
        type_OP_FilmsByTitle_InnerResult.should.contain("required_tag_list : Array");
        type_OP_FilmsByTitle_InnerResult.should.not.contain("?required_tag_list : Array");
      });

      it("...and the OP_FilmsByTitle_InnerResult should contain proper optional fields...", {
        type_OP_FilmsByTitle_InnerResult.should.contain("?optional_related_films : Array");
        type_OP_FilmsByTitle_InnerResult.should.contain("?optional_tag_list : Array");
      });

      it("...and the OP_FilmsByTitle_InnerResult should contain proper inner field types...", {
        type_OP_FilmsByTitle_InnerResult.should.contain("rrtl : Array<String>");
        type_OP_FilmsByTitle_InnerResult.should.not.contain("?rrtl : Array<String>");
        type_OP_FilmsByTitle_InnerResult.should.contain("?rotl : Array<String>");
      });

    });

  }

}
