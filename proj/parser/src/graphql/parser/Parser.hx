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

class Parser extends tink.parse.ParserBase<Pos, Err>
{
  public var document(default,null):DocumentNode;
  private var _filename:String;

  public function new(schema:String, filename:String='Untitled')
  {
    super(schema);
    _filename = filename;

    var parser = new GeneratedParser();

    var opts:ParseOptions = {};
    var lexer:Lexer = GeneratedLexer.createLexer(source, opts);

    // Parser must implement Lexer
    #if GQL_PARSER_DEBUG // for debugging, we just let it throw to get stack traces
    document = parser.parseDocument(lexer);
    #else
    try {
      document = parser.parseDocument(lexer);
    } catch (e:Err) {
      // Format and rethrow
      var posmsg = e.pos!=null ? '${ e.pos.line }: characters ${ e.pos.col }-${ e.pos.col + (e.pos.max - e.pos.min+1) }' : "";
      throw '$_filename:${ posmsg } Error: ${ e.message }';
    }
    #end
  }

  public static function syntaxError(source:Source, line:Int, lineStart:Int, start:Int, msg:String): GraphQLError
  {
    var col = start - lineStart;
    return ( { message:msg, pos:{ file:null, min:start, max:start, line:line, col:col } } : graphql.parser.Parser.Err );
  }


  /* - - - - - - - - - - - -
     - - - - - - - - - - - -
     Helpers
     - - - - - - - - - - - -
     - - - - - - - - - - - - */

  static var COMMENT_CHAR = '#'.code;
  static var EXP = @:privateAccess tink.parse.Filter.ofConst('e'.code) || @:privateAccess tink.parse.Filter.ofConst('E'.code);
  static var IDENT_START = UPPER || LOWER || '_'.code;
  static var IDENT_CONTD = IDENT_START || DIGIT;

  private function ident(error_msg:String='Identifier expected') {
    var here = false;
    return 
      if ((here && is(IDENT_START)) || (!here && upNext(IDENT_START)))
        Success(readWhile(IDENT_CONTD));
      else 
        Failure(makeError(error_msg, makePos(pos)));  
  }

  private inline function skipWhitespace(and_comments:Bool=false) {
    doReadWhile(WHITE);
    if (and_comments) {
      while (true) {
        if (is(COMMENT_CHAR)) { upto("\n"); } else { break; }
        doReadWhile(WHITE);
      }
    }
  }

  override function doSkipIgnored() skipWhitespace();
  
  // override function doMakePos(from:Int, to:Int):Pos
  // {
  //   return { file:'Untitled', min:from, max:to };
  // }

  override function makeError(message:String, pos:Pos):Err
  {
    return { message:message, pos:pos };
  }

  function mkLoc(?start:Int, ?end:Int):Location
  {
    if (start==null) start = pos;
    if (end==null) end = start;
    return { start:start, end:end, source:_filename, startToken:null, endToken:null };
  }

  function format_and_rethrow(e:Err)
  {
    var line_num = 1;
    var off = 0;
    for (i in 0...e.pos.min) if (source.fastGet(i)=="\n".code) {
      off = i;
      line_num++;
    }
    // Line number error message
    var msg = '$_filename:$line_num: characters ${ e.pos.min-off-1 }-${ e.pos.max-off-1 } Error: ${ e.message }';
    throw msg;
  }

}
