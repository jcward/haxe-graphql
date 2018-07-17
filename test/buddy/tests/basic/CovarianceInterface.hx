package tests.basic;

import buddy.*;
using buddy.Should;

class CovarianceInterface extends BuddySuite
{

  public static inline var interface_gql = '

type License implements IProvideDriverID {
  license_id:ID!
  driver_id:ID!
}

type Registration implements IProvideDriverID {
  registration_id:ID!
  driver_id:ID!
}

interface IProvideDriverID {
  driver_id:ID!
}

interface HasInterfaceCovariableIdentity {
  driver_identifier: IProvideDriverID
}
';

  public function new() {
    describe("CovarianceInterface:", {


      // NonCVPerson on interface
      it('field not relying on covairance should work', {
        var parser = new graphql.parser.Parser(interface_gql+'
type NonCVPerson implements HasInterfaceCovariableIdentity {
  person_id:ID!
  name:String!
  driver_identifier: IProvideDriverID
}
');
        var code:String = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef NonCVPerson");
        var type_NonCVPerson = Main.find_type_in_code(code, 'typedef NonCVPerson');
        type_NonCVPerson.should.contain('?driver_identifier : IProvideDriverID');
      });


      // CVPerson on interface License
      it('field relying on covairance should work', {
        var parser = new graphql.parser.Parser(interface_gql+'
type CVPerson implements HasInterfaceCovariableIdentity {
  person_id:ID!
  name:String!
  driver_identifier: License
}
');
        var code:String = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef CVPerson");
        var type_CVPerson = Main.find_type_in_code(code, 'typedef CVPerson');
        type_CVPerson.should.contain('?driver_identifier : License');
      });


      // CVPerson on interface Registration
      it('field relying on covairance should work', {
        var parser = new graphql.parser.Parser(interface_gql+'
type CVPerson implements HasInterfaceCovariableIdentity {
  person_id:ID!
  name:String!
  driver_identifier: Registration
}
');
        var code:String = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef CVPerson");
        var type_CVPerson = Main.find_type_in_code(code, 'typedef CVPerson');
        type_CVPerson.should.contain('?driver_identifier : Registration');
      });



      // Fail on field array / optionality covered in CovarianceUnion

    });
  }
}
