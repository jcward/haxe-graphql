package tests.issues;

import buddy.*;
using buddy.Should;

// Ensure that two queries that return the same enum constructor names,
// e.g. ON_PollModule and ON_TaskListModule, doesn't cause issues with
// type inference. Indeed it doesn't, because happily, everywhere we
// use those names, it's known whether we're talking about
//   OP_QueryA_InnerResult vs OP_QueryB_InnerResult
class Issue43b extends BuddySuite
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
      content_module_by_other(other: ID!): ContentModule!
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

  query GetContentModuleByOther($$other: ID!) {
      content_module_by_id(other: $$other) {
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
    describe("Issue43b:", {

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
        haxe_code.should.contain("enum OP_GetContentModuleByOther_InnerResultEnum {");
      });

      it("...and it should have two enum constructors called OP_PollModule...", {
        haxe_code.split('{\n  ON_PollModule(').length.should.beCloseTo(3);
      });

      // Haxe code compiles successfully
      it("...and we can write to /tmp/Test.hx...", function() {
        var exec_code = '
        class Test {
          public static function main() {
            test_by_id();
            test_by_other();
          }

          private static function test_by_id()
          {
            var result1:OP_GetContentModuleById_InnerResult = cast { __typename:\'PollModule\', poll_id:\'abc123\', content_type: POLL };
            var result2:OP_GetContentModuleById_InnerResult = cast { __typename:\'TaskListModule\', tasklist_id:\'xyz987\', content_type: TASKLIST };
            switch result1.as_enum() {
              case ON_PollModule(v): trace(\'YES_ID:\'+v.poll_id);
              default: \'ERROR\';
            }
            switch result2.as_enum() {
              case ON_TaskListModule(v): trace(\'YES_ID:\'+v.tasklist_id);
              default: \'ERROR\';
            }
          }

          private static function test_by_other()
          {
            var result1:OP_GetContentModuleByOther_InnerResult = cast { __typename:\'PollModule\', poll_id:\'Qabc123\', content_type: POLL };
            var result2:OP_GetContentModuleByOther_InnerResult = cast { __typename:\'TaskListModule\', tasklist_id:\'Qxyz987\', content_type: TASKLIST };
            switch result1.as_enum() {
              case ON_PollModule(v): trace(\'YES_OTHER:\'+v.poll_id);
              default: \'ERROR\';
            }
            switch result2.as_enum() {
              case ON_TaskListModule(v): trace(\'YES_OTHER:\'+v.tasklist_id);
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
        output.should.contain('YES_ID:abc123');
        output.should.contain('YES_ID:xyz987');
        output.should.contain('YES_OTHER:Qabc123');
        output.should.contain('YES_OTHER:Qxyz987');
      });

      
    });

  }

}
