package tests.extend;

import buddy.*;
using buddy.Should;

class TypeExtend extends BuddySuite
{

  public static var gql_1 = '
type SomeData {
  id:ID!
  foo:String!
}

type Query {
  get_some_data: SomeData
}

query GetSomeData {
  get_some_data {
    id
    foo
  }
}

type SSDInput { foo  : String! }
type SSDPayload { id : ID! }
type Mutation {
  set_some_data(input: SSDInput!):SSDPayload
}

';

  // Assume another file has been concatenated and extends SomeData
  public static var gql_2 = '
extend type SomeData {
  bar: Int!
}

extend type Query {
  get_some_data_with_bar: SomeData
}

query GetSomeDataWithBar {
  get_some_data_with_bar {
    id
    foo
    bar
  }
}

type SSDBarInput { foo  : String! bar : String }
extend type Mutation {
  set_some_bar_data(input: SSDInput!):SSDPayload
}

';

  public function new() {
    describe("TypeExtend:", {

      it("should parse and generate Haxe code with extended types", {
        var parser:graphql.parser.Parser = new graphql.parser.Parser(gql_1 + gql_2);
        var code = graphql.HaxeGenerator.parse(parser.document).stdout;

        var type_Query = Main.find_type_in_code(code, 'typedef Query');
        type_Query.should.contain('?get_some_data : SomeData');
        type_Query.should.contain('?get_some_data_with_bar : SomeData');

        var type_Mutation = Main.find_type_in_code(code, 'typedef Mutation');
        type_Mutation.should.contain('?set_some_data : SSDPayload');
        type_Mutation.should.contain('?set_some_bar_data : SSDPayload');
      });

      it("should parse and generate Haxe code with extended types concatenated in either order", {
        var parser:graphql.parser.Parser = new graphql.parser.Parser(gql_2 + gql_1);
        var code = graphql.HaxeGenerator.parse(parser.document).stdout;

        var type_Query = Main.find_type_in_code(code, 'typedef Query');
        type_Query.should.contain('?get_some_data : SomeData');
        type_Query.should.contain('?get_some_data_with_bar : SomeData');

        var type_Mutation = Main.find_type_in_code(code, 'typedef Mutation');
        type_Mutation.should.contain('?set_some_data : SSDPayload');
        type_Mutation.should.contain('?set_some_bar_data : SSDPayload');
      });

      it("should support multiple extensions in any order", {
        var parser:graphql.parser.Parser = new graphql.parser.Parser('
extend type Person { name:String! }
type Person { id:ID! }
extend type Person { age:Int }
extend type Person { height:Int }
');
        var code = graphql.HaxeGenerator.parse(parser.document).stdout;
        var type_Person = Main.find_type_in_code(code, 'typedef Person');
        type_Person.should.contain("id : ID");
        type_Person.should.contain("name : String");
        type_Person.should.contain("?height : Int");
        type_Person.should.contain("?age : Int");
      });

      // TODO: extend eith more interfaces, directives


    });

  }

}

