package tests.basic;

import buddy.*;
using buddy.Should;

class Interfaces extends BuddySuite
{

  public static inline var int_gql = '

interface INameOptional {
  name: String
}

interface INameRequired {
  name: String!
}

interface IHobbiesOptional {
  hobbies: [String]
}

interface IHobbiesRequired {
  hobbies: [String]!
}

interface INonNullHobbiesRequired {
  hobbies: [String!]!
}

';

  public function new() {
    describe("Interfaces:", {

      // PersonOptName
      it('a PersonOptName can implement INameOptional', {
        var parser = new graphql.parser.Parser(int_gql+'
type PersonOptName implements INameOptional {
  person_id:ID!
  name:String
}
');
        var code:String = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef PersonOptName");
        var type_PersonOptName = Main.find_type_in_code(code, 'typedef PersonOptName');
        type_PersonOptName.should.contain('?name : String'); // Generated Haxe type has optional name field
      });


      // PersonOptName fails to implement NameRequired interface
      it('a PersonOptName cannot implement INameRequired', {
        var parser = new graphql.parser.Parser(int_gql+'
type PersonOptName implements INameRequired {
  person_id:ID!
  name:String
}
');
        var err = graphql.HaxeGenerator.parse.bind(parser.document).should.throwType(String);
        err.should.contain("Type PersonOptName has optional field name, while interface INameRequired requires it");
      });
    });
  }
}
