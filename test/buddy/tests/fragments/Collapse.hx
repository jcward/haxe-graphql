package tests.fragments;

import buddy.*;
using buddy.Should;

class Collapse extends BuddySuite
{
  public static inline var gql = '

type Human implements HasName & HasAge {
  human_id:ID!
  name:String!
  age:Int!
  hair_color:String
  vision_20:Int
}

interface HasName {
  name:String!
}

interface HasAge {
  age:Int!
}

type Query {
  human_by_id(id:ID!): Human
}

# All the fragments and named fragments collapse down into the single
# Human type, so there are no unions in the result:
query HumanById($$id:ID!) {
  human_by_id(id: $$id) {
    human_id
    name

    # This will get subsumed into the base fields, as Human implements HasAge,
    # so, no extra _ON_HasAge type will be generated

    ... on HasAge { age }

    # These will get subsumed into the base fields, as Human is Human,
    # so, no extra _as_Human type will be generated
    ... on Human { vision_20 }
    ...HumanImportantDetails # Simple DRY usage

    # Nobody said they arent inane, right?
    ... on Human {

      # BTW, its fine to over-specify
      name

      ... on Human {

        # And ok to alias, even a field thats already included, now we get both:
        a_vision_score: vision_20

        ... on Human {
          human_id
          ... on Human { # ok, ok, thats enough
            hair_color
            name
            ... on Human { name }
            ... on Human { aka:name }
            ... on Human { name }
            ...HumanImportantDetails
          }
        }
      }
    }
  }
}

fragment HumanImportantDetails on Human {
  human_id
  age
  hair_color
}

';

  public function new() {
    describe("fragments.Collpase test: The Parser", {

      var parser:graphql.parser.Parser;

      it('should parse the FragmentTest document without error', {
        parser = new graphql.parser.Parser(gql);
      });

      var haxe_code:String;
      it("The HaxeGenerator should generate Haxe...", {
        var result = graphql.HaxeGenerator.parse(parser.document);
        haxe_code = result.stdout;
      });

      trace(haxe_code);

      it("...and the code should contain the and inner result...", {
        haxe_code.should.contain("typedef OP_HumanById_InnerResult");
      });
      it("...and there should be no unions because the fragments collapsed into Human...", {
        haxe_code.should.not.contain("abstract OP");
      });

      var type_OP_HumanById_InnerResult:String = "";
      it("...and the inner result type should have correct types, arrays, and optionality.", {
        var capture = false;
        for (line in haxe_code.split("\n")) {
          if (line.indexOf('typedef OP_HumanById_InnerResult')>=0) capture = true;
          if (capture==true && line=='}') capture = false;
          if (capture) type_OP_HumanById_InnerResult += line + "\n";
        }

        // inner result type, with all the right fields, aliases, and optionality:
        type_OP_HumanById_InnerResult.should.contain('human_id : ID,');
        type_OP_HumanById_InnerResult.should.contain('name : String,');
        type_OP_HumanById_InnerResult.should.contain('?a_vision_score : Int,');
        type_OP_HumanById_InnerResult.should.contain('aka : String,');
        type_OP_HumanById_InnerResult.should.contain('age : Int,');
        type_OP_HumanById_InnerResult.should.contain('?vision_20 : Int,');
        type_OP_HumanById_InnerResult.should.contain('?hair_color : String,');

        // No more, no less (even though we specified "name" and other
        // fields multiple times):
        type_OP_HumanById_InnerResult.split(':').length.should.be(8);
      });
       
      // var vars_type_of_getReturnOfTheJediQuery:String = "";
      // it("...and the vars type should have correct types and optionality.", {
      //   var capture = false;
      //   for (line in haxe_code.split("\n")) {
      //     if (line.indexOf('typedef OP_GetReturnOfTheJedi_Vars')>=0) capture = true;
      //     if (capture) vars_type_of_getReturnOfTheJediQuery += line + "\n";
      //     if (capture==true && line=='}') capture = false;
      //   }
      //  
      //   // vars type:
      //   vars_type_of_getReturnOfTheJediQuery.should.contain('typedef OP_GetReturnOfTheJedi_Vars');
      //   vars_type_of_getReturnOfTheJediQuery.should.contain('?id : ID');
      // });


      it("We can be write to /tmp/Collapse.hx...", function() {
        var exec_code = '
        class Collapse {
          public static function main() {
            greet({
              // Required fields (and aliases)
              human_id:"person123",
              name:"Joseph", aka:"Joe",
              age:33,
              // Optional fields (and aliases)
              vision_20:40, a_vision_score:40,
              hair_color:"Brown"
            });
          }
          static function greet(human:OP_HumanById_InnerResult) {
            $$type(human); // prints type to stderr
            trace("Hello "+human.name+" aka "+human.aka+", age "+human.age);
          }
        }
        ' + haxe_code;

        sys.io.File.saveContent('/tmp/Collapse.hx', exec_code);
      });

      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      it("...and the code will output the person_id type on stderr Haxe compiler!", function() {
        var p = new sys.io.Process("haxe", ["--cwd", "/tmp", "-x", "Collapse"]);
        var stdout = p.stdout.readAll().toString();
        var stderr = p.stderr.readAll().toString();
        stderr.should.contain('OP_HumanById_InnerResult');
        stdout.should.contain('Hello Joseph aka Joe, age 33');
      });

    });
  }

}

