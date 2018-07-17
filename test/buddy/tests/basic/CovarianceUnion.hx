package tests.basic;

import buddy.*;
using buddy.Should;

class CovarianceUnion extends BuddySuite
{

  public static inline var union_gql = '

type License {
  license_id:ID!
}

type Registration {
  registration_id:ID!
}

union EitherLicenseOrRegistration = License | Registration

interface HasUnionCovariableIdentity {
  info: EitherLicenseOrRegistration
}
';

  public function new() {
    describe("CovarianceUnion:", {


      // NonCVPerson on union
      it('field not relying on covairance should work', {
        var parser = new graphql.parser.Parser(union_gql+'
type NonCVPerson implements HasUnionCovariableIdentity {
  person_id:ID!
  name:String!
  info: EitherLicenseOrRegistration
}
');
        var code:String = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef NonCVPerson");
        var type_NonCVPerson = Main.find_type_in_code(code, 'typedef NonCVPerson');
        type_NonCVPerson.should.contain('?info : EitherLicenseOrRegistration');
      });


      // CVPerson on union's License
      it('field relying on covairance should work', {
        var parser = new graphql.parser.Parser(union_gql+'
type CVPerson implements HasUnionCovariableIdentity {
  person_id:ID!
  name:String!
  info: License
}
');
        var code:String = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef CVPerson");
        var type_CVPerson = Main.find_type_in_code(code, 'typedef CVPerson');
        type_CVPerson.should.contain('?info : License');
      });



      // CVPerson on union's Registration
      it('field relying on covairance should work', {
        var parser = new graphql.parser.Parser(union_gql+'
type CVPerson implements HasUnionCovariableIdentity {
  person_id:ID!
  name:String!
  info: Registration
}
');
        var code:String = graphql.HaxeGenerator.parse(parser.document).stdout;
        code.should.contain("typedef CVPerson");
        var type_CVPerson = Main.find_type_in_code(code, 'typedef CVPerson');
        type_CVPerson.should.contain('?info : Registration');
      });



      // CVPerson fail on array mismatch
      it('field relying on covairance should work', {
        var parser = new graphql.parser.Parser(union_gql+'
type CVPerson implements HasUnionCovariableIdentity {
  person_id:ID!
  name:String!
  info: [License]
}
');
        var err = graphql.HaxeGenerator.parse.bind(parser.document).should.throwType(String);
        err.should.contain("Type CVPerson implements HasUnionCovariableIdentity");
        err.should.contain("field info");
        err.should.contain("List vs non-List");
      });



      // CVPerson fail on optionality mismatch
      it('field relying on covairance should work', {
        var parser = new graphql.parser.Parser(union_gql+'
type CVPerson implements HasUnionCovariableIdentity {
  person_id:ID!
  name:String!
  info: License!
}
');
        var err = graphql.HaxeGenerator.parse.bind(parser.document).should.throwType(String);
        err.should.contain("Type CVPerson implements HasUnionCovariableIdentity");
        err.should.contain("field info");
        err.should.contain("nullable vs non-nullable");
      });

    });
  }
}
