// npm GraphQL Parser from 'graphql':
const GraphQL = require('graphql');
const fs = require('fs');
const hx = require('./hxgen.js');

// Read source, parse to GraphQL AST Document
var src = fs.readFileSync( 'test/StarWarsTest.gql' );
var s = new GraphQL.Source( src );
var doc = GraphQL.parse( s );

// Pass to HaxeGenerator
var result = hx.graphql.HaxeGenerator.parse_graphql_doc(doc);
var exit_code = result.stderr.length > 0 ? 1 : 0;

if (exit_code>0) {
  console.log(result.stderr);
  console.log('Exiting with parse errors!');
  process.exit(exit_code);
} else {
  // Success, write output .hx file
  var outfile = 'GQLTypes.hx';
  fs.writeFileSync(outfile, result.stdout);
  console.log('Wrote '+outfile);
  console.log(result.stdout);
  process.exit(0);
}
