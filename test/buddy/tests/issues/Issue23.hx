package tests.issues;

import buddy.*;
using buddy.Should;

class Issue23 extends BuddySuite
{
  // TODO: directives:  content @include(if: $include_content) {

  public static inline var gql = '

type Query {
  by_title(title:String!): [FilmData]
}

type FilmData {
  id: ID!
  title: String
  related_films: [ID]
  tag_list: [String]!
}

query FilmsByTitle($$title: String!) {
  by_title(title:$$title) {
    id
    title
    related_films
    tag_list
  }
}

';

  public function new() {
    describe("Issue23:", {

      var parser:graphql.parser.Parser;

      it('should parse this query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      var query_OP_FilmsByTitle_Result_type:String = "";
      it("...and the OP_FilmsByTitle_Result should exist...", {
        var capture = false;
        for (line in haxe_code.split("\n")) {
          if (line.indexOf('typedef OP_FilmsByTitle_Result')>=0) capture = true;
          if (capture==true && line=='}') capture = false;
          if (capture) query_OP_FilmsByTitle_Result_type += line + "\n";
        }

        query_OP_FilmsByTitle_Result_type.split(":").length.should.be(2);
      });

     
      var query_OP_FilmsByTitle_InnerResult_type:String = "";
      it("...and the OP_FilmsByTitle_InnerResult should exist...", {
        var capture = false;
        for (line in haxe_code.split("\n")) {
          if (line.indexOf('typedef OP_FilmsByTitle_InnerResult')>=0) capture = true;
          if (capture==true && line=='}') capture = false;
          if (capture) query_OP_FilmsByTitle_InnerResult_type += line + "\n";
        }

        query_OP_FilmsByTitle_InnerResult_type.split("\n").length.should.be(6);
      });

      it("...and have the correct ID type...", {
        query_OP_FilmsByTitle_InnerResult_type.should.contain("id : ID");
        query_OP_FilmsByTitle_InnerResult_type.should.not.contain("?id : ID");
      });

      it("...and the correct title type...", {
        query_OP_FilmsByTitle_InnerResult_type.should.contain("?title : String");
      });

      it("...and the correct tag_list type...", {
        query_OP_FilmsByTitle_InnerResult_type.should.contain("tag_list : Array<String>");
        query_OP_FilmsByTitle_InnerResult_type.should.not.contain("?tag_list");
      });

      it("...and the correct related_films type...", {
        query_OP_FilmsByTitle_InnerResult_type.should.contain("?related_films : Array<ID>");
      });

    });

  }

}
