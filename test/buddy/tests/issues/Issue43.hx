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

      it('should parse this query document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

    });

  }

}
