package graphql.parser;

import hxparse.Parser.parse as parse;

private enum Kwd {
  KwdEnum;
}

private enum Token {
  TBrOpen;
  TBrClose;
  TIdent(s:String);
  // TComma;
  // TDblDot;
  // TBkOpen;
  // TBkClose;
  // TDash;
  // TDot;
  // TTrue;
  // TFalse;
  // TNull;
  // TNumber(v:String);
  // TString(v:String);
  TEof;
}

class GraphQLLexer extends hxparse.Lexer
  /* FYI, cannot be used at compiletime: implements hxparse.RuleBuilder -
   instead use Lexer.buildRuleset */
{

  static var buf:StringBuf;

  // static function mk(lexer:Lexer, td) {
  //   return new Token(td, mkPos(lexer.curPos()));
  // }
  static var ident = "_*[a-z][a-zA-Z0-9_]*|_+|_+[0-9][_a-zA-Z0-9]*";

  // Use buildRuleset instead of @:rule / RuleBuilder
  public static var kwd = hxparse.Lexer.buildRuleset([
    { rule:"enum", func:function(lexer) return KwdEnum },
  ]);

  // Use buildRuleset instead of @:rule / RuleBuilder
  public static var tok = hxparse.Lexer.buildRuleset([
    { rule:"{", func:function(lexer) return TBrOpen },
    { rule:"}", func:function(lexer) return TBrClose },
    { rule:"[\r\n\t ]", func:function(lexer) return lexer.token(tok) },
    { rule:"", func:function(lexer) return TEof },
    { rule:ident, func:function(lexer) {
      // var kwd = keywords.get(lexer.current);
      // return (kwd != null) ? mk(lexer, Kwd(kwd)) :
      //   mk(lexer, Const(CIdent(lexer.current)));
        return TIdent(lexer.current);
    } },
  ]);

    /*
 @:rule [
    "{" => TBrOpen,
    "}" => TBrClose,
    "," => TComma,
    ":" => TDblDot,
    "[" => TBkOpen,
    "]" => TBkClose,
    "-" => TDash,
    "\\." => TDot,
    "true" => TTrue,
    "false" => TFalse,
    "null" => TNull,
    "-?(([1-9][0-9]*)|0)(.[0-9]+)?([eE][\\+\\-]?[0-9]+)?" => TNumber(lexer.current),
    '"' => {
      buf = new StringBuf();
      lexer.token(string);
      TString(buf.toString());
    },

    // Skip whitespace
    "[\r\n\t ]" => lexer.token(tok),
    "" => TEof
  ];
    */

    /*
  static var string = @:rule [
    "\\\\t" => {
      buf.addChar("\t".code);
      lexer.token(string);
    },
    "\\\\n" => {
      buf.addChar("\n".code);
      lexer.token(string);
    },
    "\\\\r" => {
      buf.addChar("\r".code);
      lexer.token(string);
    },
    '\\\\"' => {
      buf.addChar('"'.code);
      lexer.token(string);
    },
    "\\\\u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]" => {
      buf.add(String.fromCharCode(Std.parseInt("0x" +lexer.current.substr(2))));
      lexer.token(string);
    },
    '"' => {
      lexer.curPos().pmax;
    },
    '[^"]' => {
      buf.add(lexer.current);
      lexer.token(string);
    },
  ];
    */
}

class GQLParser extends hxparse.Parser<hxparse.LexerTokenSource<Token>, Token> {
  public function new(input:byte.ByteData, sourceName:String='untitled') {
    var lexer = new GraphQLLexer(input, sourceName);
    var ts = new hxparse.LexerTokenSource(lexer, GraphQLLexer.tok);
    super(ts);
  }

  public function parseGraphQL():Dynamic {
    return parse(switch stream {
      case [TBrOpen, obj = insideBraces({})]: obj;
      case [TIdent(s)]: s;
      // case [TNumber(s)]: s;
      // case [TTrue]: true;
      // case [TFalse]: false;
      // case [TNull]: null;
      // case [TString(s)]: s;
    });
  }

  function insideBraces(obj:{}) {
    return parse(switch stream {
      case [TBrClose]: obj;
      // case [TString(s), TDblDot, e = parseGraphQL()]:
      //   Reflect.setField(obj, s, e);
      //   switch stream {
      //     case [TBrClose]: obj;
      //     case [TComma]: object(obj);
      //   }
    });
  }

  // function array(acc:Array<Dynamic>) {
  //   return parse(switch stream {
  //     case [TBkClose]: acc;
  //     case [elt = parseGraphQL()]:
  //       acc.push(elt);
  //       switch stream {
  //         case [TBkClose]: acc;
  //         case [TComma]: array(acc);
  //       }
  //   });
  // }
}
