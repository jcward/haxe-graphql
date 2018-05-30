// npm GraphQL Parser from 'graphql':
const args = require('commander');
const GraphQL = require('graphql');
const fs = require('fs');
const hx = require('../dist/hxgen.js');
const path = require('path');
const package = require('../package.json');
const mkDirByPathSync = require('./mkdir_util.js').mkDirByPathSync;

// Parse gql2hx CLI arguments
args
  .version(package.version, '-v, --version')
  .description(package.name + ' ' + package.version + ' - ' + package.description)
  .usage('-i <file> [-o <outfile>] [-p <package name>] [-g generate]')
  .option('-i, --infile [infile]', 'Input .graphql file (or "stdin")', null)
  .option('-o, --outfile [outfile]', 'Output .hx file (or "stdout")', "stdout")
//  .option('-p, --package [package]', 'Output Haxe package (e.g. "pkg.subpkg")', "")
//  .option('-g, --generate [generate]', 'Generate "typedefs" or "classes" and interfaces', "typedefs")
  .parse(process.argv);

if (args.infile==null) {
  args.outputHelp();
  process.exit(1);
}

// try/catch helper
function build_step(msg, func) {
  try {
    func();
  } catch (e) {
    console.error('Error '+msg+':\n'+e);
    process.exit(1);
  }
}

// Read input file
var input_filename = args.infile;
var input = null;
build_step('reading input '+input_filename, function() {
  input = (input_filename=="stdin") ? fs.readFileSync(0) : fs.readFileSync(input_filename);
});

// Parse .graphql to AST
var ast_document = null;
build_step('parsing GraphQL', function() {
  var s = new GraphQL.Source( input.toString(), input_filename );
  ast_document = GraphQL.parse( s );
});

// Pass to HaxeGenerator
var result = null;
build_step('generating Haxe', function() {
  var opts = { generate:args.generate, disable_null_wrappers:args.disable_null_wrappers };
  result = hx.graphql.HaxeGenerator.parse(ast_document, opts);
  if (result.stderr.length>0) throw result.stderr;
});

// Write output file (or STDOUT)
var output_filename = args.outfile;
build_step('writing output', function() {
  if (output_filename=='stdout') {
    console.log(result.stdout);
  } else {
    var out_dir = output_filename.substr(0, output_filename.lastIndexOf(path.sep));
    mkDirByPathSync(out_dir);
    fs.writeFileSync(output_filename, result.stdout);
    console.log('Wrote '+output_filename);
  }
});

// Finished without errors!
process.exit(0);
