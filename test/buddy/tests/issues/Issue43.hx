package tests.issues;

import buddy.*;
using buddy.Should;

class Issue43 extends BuddySuite
{
  public static inline var gql = 
  '
    enum ContentModuleType 
    {
      POLL
      TASKLIST
    }
    type TaskListModule {
      content_type: ContentModuleType!
      tasklist_id: ID!
    }
    type PollModule {
      content_type: ContentModuleType!
      poll_id: ID!
    }
    union ContentModule = PollModule | TaskListModule
    type Query
    {
      content_module_by_id(id: ID!): ContentModule!
    }

    query GetContentModuleById($$id: ID!) {
      content_module_by_id(id: $$id) {
        __typename
        ... on TaskListModule {
          content_type
          tasklist_id
        }
        ... on PollModule {
          content_type
          poll_id
        }
      }
    }
    
  ';

  public function new() {
    describe("Issue43:", {

      var parser:graphql.parser.Parser;

      // Parser successfully generates Haxe code
      it('should parse this query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      // Haxe code has the expected definitions
      it("...and it should have an enum definition...", {
        haxe_code.should.contain("enum OP_GetContentModuleById_InnerResultEnum {");
      });

      it("...and it should have typedefs for each of the typenames...", {
        haxe_code.should.contain("typedef OP_GetContentModuleById_InnerResult_ON_TaskListModule = {");
        haxe_code.should.contain("typedef OP_GetContentModuleById_InnerResult_ON_PollModule = {");
      });

      it("...and it should have an as_enum function...", {
        haxe_code.should.contain("as_enum()");
      });

      // Haxe code compiles successfully
      it("...and we can write to /tmp/Test.hx...", function() {
        var exec_code = '
        class Test {
          public static function main() {
            var result1:OP_GetContentModuleById_InnerResult = cast { __typename:\'PollModule\', poll_id:\'abc123\', content_type: POLL };
            var result2:OP_GetContentModuleById_InnerResult = cast { __typename:\'TaskListModule\', tasklist_id:\'xyz987\', content_type: TASKLIST };
            switch result1.as_enum() {
              case ON_PollModule(v): trace(\'YES:\'+v.poll_id);
              default: \'ERROR\';
            }
            switch result2.as_enum() {
              case ON_TaskListModule(v): trace(\'YES:\'+v.tasklist_id);
              default: \'ERROR\';
            }
          }
        }
        ' + haxe_code;

        sys.io.File.saveContent('/tmp/Test.hx', exec_code);
      });

      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      it("...and the code, if it's valid, will be executed by the Haxe compiler!", function() {
        var output = new sys.io.Process("haxe", ["--cwd", "/tmp", "-x", "Test"]).stdout.readAll().toString();
        output.should.contain('YES:abc123');
        output.should.contain('YES:xyz987');
      });

      
    });

  }

}
