package graphql.parser;

import graphql.ASTDefs;

import tink.parse.ParserBase;
import tink.parse.Char.*;

using tink.CoreApi;

import graphql.parser.GeneratedParser;
import graphql.parser.GeneratedLexer;

@:structInit
class Pos {
  public var file:String;
  public var min:Int;
  public var max:Int;
  public var line:Int;
  public var col:Int;
}

@:structInit
class Err {
  public var message:String;
  public var pos:Pos;
}

// TODO: no longer necessary to extend tink parser, but still using StringSlice
class Parser extends tink.parse.ParserBase<Pos, Err>
{
  public var document(default,null):DocumentNode;

  public function new(schema:String, ?options:ParseOptions, ?filename:String='Untitled')
  {
    super(schema);

    var parser = new GeneratedParser();
    var lexer:Lexer = GeneratedLexer.createLexer(source, options);

    // Parser must implement Lexer
    #if GQL_PARSER_DEBUG // for debugging, we just let it throw to get stack traces
    document = parser.parseDocument(lexer);
    #else
    try {
      document = parser.parseDocument(lexer);
    } catch (e:Err) {
      // Format and rethrow
      var posmsg = e.pos!=null ? '${ e.pos.line }: characters ${ e.pos.col }-${ e.pos.col + (e.pos.max - e.pos.min+1) }' : "";
      throw '$filename:${ posmsg } Error: ${ e.message }';
    }
    #end
  }

  public static function syntaxError(source:Source, line:Int, lineStart:Int, start:Int, msg:String): GraphQLError
  {
    var col = start - lineStart;
    return ( { message:msg, pos:{ file:null, min:start, max:start, line:line, col:col } } : graphql.parser.Parser.Err );
  }

}
