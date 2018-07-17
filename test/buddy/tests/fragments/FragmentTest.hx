package tests.fragments;

import buddy.*;
using buddy.Should;

class FragmentTest extends BuddySuite
{
  // TODO: directives:  content @include(if: $include_content) {

  public static inline var gql = '

interface HasName {
  name:String!
}

union Being = Person | Dog

interface Job {
  title:String!
}

type Programmer implements Job {
  title:String!
  programmer_id:ID!
  favorite_language: String!
}

type Plumber implements Job {
  title:String!
  plumber_id:ID!
  favorite_wrench: String!
}

type Person implements HasName {
  person_id:ID!
  name:String!
  job:Job
}

type Dog implements HasName {
  dog_id:ID!
  name:String!
}

type Query {
  by_name(name:String!): HasName
}

query ByName($$name:String!) {
  by_name(name: $$name) {
    name

    # Simple DRY fragment on expected type (note: field is double specified)
    ...JustName

    # Inline Fragment on a ceratin implementor of this interface
    ... on Person {
      ...PersonDetails # named fragment on this expected type

      job {
        title
        ... on Plumber {
          plumber_id
          ...PlumberDetails
        }
      }
    }

    ... on Dog {
      dog_id
    }

  }
}


fragment JustName on HasName {
  name
}

fragment PersonDetails on Person {
  person_id
}

fragment PlumberDetails on Plumber {
  plumber_id
  favorite_wrench
}

';

  public function new() {
    describe("FragmentTest: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the FragmentTest document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      it("should parse 12 definitions from this schema", {
        parser.document.definitions.length.should.be(12);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      it("...and the query result and inner result union types should be present...", {
        haxe_code.should.contain("typedef OP_ByName_Result");
        haxe_code.should.contain("abstract OP_ByName_InnerResult(Dynamic)");
        haxe_code.should.contain("abstract OP_ByName_InnerResult__job(Dynamic)");
      });

      it("...and the inner result type should have correct types.", {
        var type_OP_ByName_InnerResult = Main.find_type_in_code(haxe_code, 'abstract OP_ByName_InnerResult(Dynamic)');

        // inner result type:
        type_OP_ByName_InnerResult.should.contain('fromOP_ByName_InnerResult_ON_Dog');
        type_OP_ByName_InnerResult.should.contain('fromOP_ByName_InnerResult_ON_Person');
        type_OP_ByName_InnerResult.split(':from').length.should.be(3);
      });

      it("...and the inner result job type should have correct types.", {
        var type_OP_ByName_InnerResult__job = Main.find_type_in_code(haxe_code, 'abstract OP_ByName_InnerResult__job(Dynamic)');
        // Main.print(type_OP_ByName_InnerResult__job);

        // inner result type:
        type_OP_ByName_InnerResult__job.should.contain('fromOP_ByName_InnerResult__job_ON_Plumber');
        type_OP_ByName_InnerResult__job.should.contain('fromOP_ByName_InnerResult__job_ON_Programmer');
        type_OP_ByName_InnerResult__job.split(':from').length.should.be(3);
      });

      it("We can be write to /tmp/FragmentTest.hx...", function() {
        var exec_code = '
        class FragmentTest {
          public static function main() {
            var q:OP_ByName_InnerResult = {
              name:"qqq",
              person_id:"person123"
            };
            $$type(q);                 // prints type to stderr
            trace("and we executed");  // prints to stdout
          }
        }
        ' + haxe_code;

        sys.io.File.saveContent('/tmp/FragmentTest.hx', exec_code);
      });

      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      it("...and the code will output the person_id type on stderr Haxe compiler!", function() {
        var p = new sys.io.Process("haxe", ["--cwd", "/tmp", "-x", "FragmentTest"]);
        var stdout = p.stdout.readAll().toString();
        var stderr = p.stderr.readAll().toString();
        stderr.should.contain('Warning : OP_ByName_InnerResult');
        stdout.should.contain('and we executed');
      });

    });
  }

}
