package graphql.parser;

import graphql.ASTDefs;
import graphql.parser.Parser;

import tink.parse.ParserBase;
import tink.parse.Char.*;

using tink.CoreApi;

using graphql.parser.ParserHelper;

@:structInit
class Pos {
  public var file:String;
  public var min:Int;
  public var max:Int;
}

@:structInit
class Err {
  public var message:String;
  public var pos:Pos;
}

@:access(graphql.parser.Parser)
class ParserHelper
{
  public static function mkLoc(p:Parser, ?start:Int, ?end:Int):Location
  {
    if (start==null) start = p.pos;
    if (end==null) end = start;
    return { start:start, end:end, source:p._filename, startToken:null, endToken:null };
  }

  public inline static function COMMENT_CHAR(?p:Parser) return '#'.code;
  public inline static function EXP(?p:Parser) return @:privateAccess tink.parse.Filter.ofConst('e'.code) || @:privateAccess tink.parse.Filter.ofConst('E'.code);
  public inline static function IDENT_START(?p:Parser) return UPPER || LOWER || '_'.code;
  public inline static function IDENT_CONTD(?p:Parser) return IDENT_START() || DIGIT;

  // http://facebook.github.io/graphql/October2016/#sec-Line-Terminators
  private static inline var NL = 0x10;
  private static inline var CR = 0x13;
  public static inline function is_newline_at(p:Parser, pos:Int)
  {
    var ahead_is_nl = pos<p.source.length && p.source.fastGet(pos+1)==NL;
    var behind_is_cr = pos>0 && p.source.fastGet(pos-1)==CR;
    var cur = p.source.fastGet(pos);
    var rtn = false;
    if (cur==NL && !behind_is_cr) {
      rtn = true;
    } else if (cur==CR && !ahead_is_nl) {
      rtn = true;
    }
    return rtn;
  }

  public static function format_and_rethrow(p:Parser, e:Err)
  {
    var line_num = 1;
    var off = 0;
    for (i in 0...e.pos.min) if (is_newline_at(p, i)) {
      off = i;
      line_num++;
    }
    // Line number error message
    var msg = '${ p._filename }:$line_num: characters ${ e.pos.min-off }-${ e.pos.max-off } Error: ${ e.message }';
    throw msg;
  }

  public static function ident(p:Parser, here = false) {
    return 
      if ((here && p.is(IDENT_START())) || (!here && p.upNext(IDENT_START())))
        Success(p.readWhile(IDENT_CONTD()));
      else 
        Failure(p.makeError('Identifier expected', p.makePos(p.pos)));  
  }

  public static inline function skipWhitespace(p:Parser, and_comments:Bool=false) {
    p.doReadWhile(WHITE);
    if (and_comments) {
      while (true) {
        if (p.is(COMMENT_CHAR())) { p.upto("\n"); } else { break; }
        p.doReadWhile(WHITE);
      }
    }
  }

}
