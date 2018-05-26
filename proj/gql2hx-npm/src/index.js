// npm GraphQL Parser from 'graphql':
const GraphQL = require('graphql');
const fs = require('fs');
const hx = require('../dist/hxgen.js');

// Read source
// TODO: input file or stdin
var src = fs.readFileSync( 'test/StarWarsTest.gql' );

// Parse to GraphQL AST Document with graphql module
var s = new GraphQL.Source( src );
var ast_document = GraphQL.parse( s );

// Pass to HaxeGenerator
console.log('TODO: cli args --> HxGenOptions');
var opts = null;
var result = hx.graphql.HaxeGenerator.parse(ast_document, opts);
var exit_code = result.stderr.length > 0 ? 1 : 0;

if (exit_code>0) {
  console.log(result.stderr);
  console.log('Exiting with parse errors!');
  process.exit(exit_code);
} else {
  // Success, write output .hx file TODO: args
  //var outfile = 'GQLTypes.hx';
  //fs.writeFileSync(outfile, result.stdout);
  //console.log('Wrote '+outfile);
  console.log(result.stdout);
  process.exit(0);
}
