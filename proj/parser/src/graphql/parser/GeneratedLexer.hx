package graphql.parser;

/* GENERATED BY gen_lexer.rb -- DO NOT EDIT!!! */
/* GENERATED BY gen_lexer.rb -- DO NOT EDIT!!! */
/* GENERATED BY gen_lexer.rb -- DO NOT EDIT!!! */
/* GENERATED BY gen_lexer.rb -- DO NOT EDIT!!! */
/* */
/* based on: http://127.0.0.1/lexer.js */
/* */

import graphql.ASTDefs;

import graphql.parser.GeneratedParser;

/**
 * Copyright (c) 2015-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict
 */

/* import type { Token } from './ast';
import type { Source } from './source';
import { syntaxError } from '../error';
import blockStringValue from './blockStringValue'; */

/**
 * Given a Source object, this returns a Lexer for that source.
 * A Lexer is a stateful stream generator in that every time
 * it is advanced, it returns the next token in the Source. Assuming the
 * source lexes, the final Token emitted by the lexer will be of kind
 * EOF, after which the lexer will repeatedly return the same EOF token
 * whenever called.
 */
class GeneratedLexer<TOptions> {

public var source:Source;
public var options:TOptions;
public var lastToken:Token;
public var token:Token;
public var line:Int = 1;
public var lineStart:Int = 0;
public var advance:Void->Token;

private function new(opts:TOptions) {
  this.options = opts;
  this.advance = advanceLexer; // odd redirection by .js code
}

public static function createLexer<TOptions>(source:Source, options:TOptions) {
  var startOfFileToken = TokUtil.asToken(TokenKind.SOF, 0, 0, 0, 0, null);
  var lexer = new GeneratedLexer(options);
  lexer.source = source;
  lexer.lastToken = startOfFileToken;
  lexer.token = startOfFileToken;
  return lexer;
}


private function advanceLexer() {
  this.lastToken = this.token;
  var token = (this.token = this.lookahead());
  return token;
}

public function lookahead() {
  var token = this.token;
  if (token.kind != TokenKind.EOF) {
    do {
      // Note: next is only mutable during parsing, so we cast to allow this.
      token = (token.next!=null) ? token.next : ((token:Dynamic).next = readToken(cast this, token));
    } while (token.kind == TokenKind.COMMENT);
  }
  return token;
}

/**
 * The return type of createLexer.
 */


/**
 * An exported enum describing the different kinds of tokens that the
 * lexer emits.
 */


/**
 * The enum type representing the token kinds values.
 */


/**
 * A helper function to describe a token as a string for debugging
 */
/* public function getTokenDesc(token: Token):String {
  var value = token.value;
  return value ? '${token.kind} "${value}"' : token.kind;
} */

/* var charCodeAt = String.prototype.charCodeAt;
var slice = String.prototype.slice; */

/**
 * Helper function for constructing the Token object.
 */


private function printCharCode(code) {
  return (
    // NaN/undefined represents access beyond the end of the file.
    false /* isNaN(code) */
      ? TokenKind.EOF
      : // Trust JSON for ASCII.
        code < 0x007f
        ? haxe.Json.stringify(String.fromCharCode(code))
        : // Otherwise print the escaped form.
           'ESCMAD' // escaping madness
  );
}

/**
 * Gets the next token from the source starting at the given position.
 *
 * This skips over whitespace and comments until it finds the next lexable
 * token, then lexes punctuators immediately or calls the appropriate helper
 * function for more complicated tokens.
 */
private function readToken(lexer: Lexer, prev: Token): Token {
  var source = lexer.source;
  var body = source/* source.body */;
  var bodyLength = body.length;

  var pos = positionAfterWhitespace(body, prev.end, lexer);
  var line = lexer.line;
  var col = 1 + pos - lexer.lineStart;

  if (pos >= bodyLength) {
    return TokUtil.asToken(TokenKind.EOF, bodyLength, bodyLength, line, col, prev);
  }

  var code = /* CCA */source.fastGet(pos);

  // SourceCharacter
  if (code < 0x0020 && code != 0x0009 && code != 0x000a && code != 0x000d) {
    throw syntaxError(
      source,
      pos,
      'Cannot contain the invalid character ${printCharCode(code)}.');
  }

  switch (code) {
    // !
    case 33:
      return TokUtil.asToken(TokenKind.BANG, pos, pos + 1, line, col, prev);
    // #
    case 35:
      return readComment(source, pos, line, col, prev);
    // $
    case 36:
      return TokUtil.asToken(TokenKind.DOLLAR, pos, pos + 1, line, col, prev);
    // &
    case 38:
      return TokUtil.asToken(TokenKind.AMP, pos, pos + 1, line, col, prev);
    // (
    case 40:
      return TokUtil.asToken(TokenKind.PAREN_L, pos, pos + 1, line, col, prev);
    // )
    case 41:
      return TokUtil.asToken(TokenKind.PAREN_R, pos, pos + 1, line, col, prev);
    // .
    case 46:
      if (
        /* CCA */source.fastGet(pos + 1) == 46 &&
        /* CCA */source.fastGet(pos + 2) == 46
      ) {
        return TokUtil.asToken(TokenKind.SPREAD, pos, pos + 3, line, col, prev);
      }
      /* brcaseeak; */
    // :
    case 58:
      return TokUtil.asToken(TokenKind.COLON, pos, pos + 1, line, col, prev);
    // =
    case 61:
      return TokUtil.asToken(TokenKind.EQUALS, pos, pos + 1, line, col, prev);
    // @
    case 64:
      return TokUtil.asToken(TokenKind.AT, pos, pos + 1, line, col, prev);
    // [
    case 91:
      return TokUtil.asToken(TokenKind.BRACKET_L, pos, pos + 1, line, col, prev);
    // ]
    case 93:
      return TokUtil.asToken(TokenKind.BRACKET_R, pos, pos + 1, line, col, prev);
    // {
    case 123:
      return TokUtil.asToken(TokenKind.BRACE_L, pos, pos + 1, line, col, prev);
    // |
    case 124:
      return TokUtil.asToken(TokenKind.PIPE, pos, pos + 1, line, col, prev);
    // }
    case 125:
      return TokUtil.asToken(TokenKind.BRACE_R, pos, pos + 1, line, col, prev);
    // A-Z _ a-z
    case 65 | /*CFT*/ 66 | /*CFT*/ 67 | /*CFT*/ 68 | /*CFT*/ 69 | /*CFT*/ 70 | /*CFT*/ 71 | /*CFT*/ 72 | /*CFT*/ 73 | /*CFT*/ 74 | /*CFT*/ 75 | /*CFT*/ 76 | /*CFT*/ 77 | /*CFT*/ 78 | /*CFT*/ 79 | /*CFT*/ 80 | /*CFT*/ 81 | /*CFT*/ 82 | /*CFT*/ 83 | /*CFT*/ 84 | /*CFT*/ 85 | /*CFT*/ 86 | /*CFT*/ 87 | /*CFT*/ 88 | /*CFT*/ 89 | /*CFT*/ 90 | /*CFT*/ 95 | /*CFT*/ 97 | /*CFT*/ 98 | /*CFT*/ 99 | /*CFT*/ 100 | /*CFT*/ 101 | /*CFT*/ 102 | /*CFT*/ 103 | /*CFT*/ 104 | /*CFT*/ 105 | /*CFT*/ 106 | /*CFT*/ 107 | /*CFT*/ 108 | /*CFT*/ 109 | /*CFT*/ 110 | /*CFT*/ 111 | /*CFT*/ 112 | /*CFT*/ 113 | /*CFT*/ 114 | /*CFT*/ 115 | /*CFT*/ 116 | /*CFT*/ 117 | /*CFT*/ 118 | /*CFT*/ 119 | /*CFT*/ 120 | /*CFT*/ 121 | /*CFT*/ 122:
      return readName(source, pos, line, col, prev);
    // - 0-9
    case 45 | /*CFT*/ 48 | /*CFT*/ 49 | /*CFT*/ 50 | /*CFT*/ 51 | /*CFT*/ 52 | /*CFT*/ 53 | /*CFT*/ 54 | /*CFT*/ 55 | /*CFT*/ 56 | /*CFT*/ 57:
      return readNumber(source, pos, code, line, col, prev);
    // "
    case 34:
      if (
        /* CCA */source.fastGet(pos + 1) == 34 &&
        /* CCA */source.fastGet(pos + 2) == 34
      ) {
        return readBlockString(source, pos, line, col, prev);
      }
      return readString(source, pos, line, col, prev);
  }

  throw syntaxError(source, pos, unexpectedCharacterMessage(code));
}

/**
 * Report a message that an unexpected character was encountered.
 */
private function unexpectedCharacterMessage(code) {
  if (code == 39) {
    // '
    return (
      "Unexpected single quote character ('), did you mean to use " +
      'a double quote (")?'
    );
  }

  return 'Cannot parse the unexpected character ' + printCharCode(code) + '.';
}

/**
 * Reads from body starting at startPosition until it finds a non-whitespace
 * or commented character, then returns the position of that character for
 * lexing.
 */
private function positionAfterWhitespace(
  body:Source,
  startPosition:Int /* number */,
  lexer: Lexer):Int /* number */ 
{
  var bodyLength = body.length;
  var position = startPosition;
  while (position < bodyLength) {
    var code = /* CCA */source.fastGet(position);
    // tab | space | comma | BOM
    if (code == 9 || code == 32 || code == 44 || code == 0xfeff) {
      ++position;
    } else if (code == 10) {
      // new line
      ++position;
      ++lexer.line;
      lexer.lineStart = position;
    } else if (code == 13) {
      // carriage return
      if (/* CCA */source.fastGet(position + 1) == 10) {
        position += 2;
      } else {
        ++position;
      }
      ++lexer.line;
      lexer.lineStart = position;
    } else {
      break;
    }
  }
  return position;
}

/**
 * Reads a comment token from the source file.
 *
 * #[\u0009\u0020-\uFFFF]*
 */
private function readComment(source:Source, start, line, col, prev): Token {
  var body = source/* source.body */;
  var code;
  var position = start;

  do {
    code = /* CCA */source.fastGet(++position);
  } while (
    code != null &&
    // SourceCharacter but not LineTerminator
    (code > 0x001f || code == 0x0009)
  );

  return TokUtil.asToken(
    TokenKind.COMMENT,
    start,
    position,
    line,
    col,
    prev,
    /* CCA */body.slice(start + 1 ...  position));
}

/**
 * Reads a number token from the source file, either a float
 * or an int depending on whether a decimal point appears.
 *
 * Int:   -?(0|[1-9][0-9]*)
 * Float: -?(0|[1-9][0-9]*)(\.[0-9]+)?((E|e)(+|-)?[0-9]+)?
 */
private function readNumber(source:Source, start, firstCode, line, col, prev): Token {
  var body = source/* source.body */;
  var code = firstCode;
  var position = start;
  var isFloat = false;

  if (code == 45) {
    // -
    code = /* CCA */source.fastGet(++position);
  }

  if (code == 48) {
    // 0
    code = /* CCA */source.fastGet(++position);
    if (code >= 48 && code <= 57) {
      throw syntaxError(
        source,
        position,
        'Invalid number, unexpected digit after 0: ${printCharCode(code)}.');
    }
  } else {
    position = readDigits(source, position, code);
    code = /* CCA */source.fastGet(position);
  }

  if (code == 46) {
    // .
    isFloat = true;

    code = /* CCA */source.fastGet(++position);
    position = readDigits(source, position, code);
    code = /* CCA */source.fastGet(position);
  }

  if (code == 69 || code == 101) {
    // E e
    isFloat = true;

    code = /* CCA */source.fastGet(++position);
    if (code == 43 || code == 45) {
      // + -
      code = /* CCA */source.fastGet(++position);
    }
    position = readDigits(source, position, code);
  }

  return TokUtil.asToken(
    isFloat ? TokenKind.FLOAT : TokenKind.INT,
    start,
    position,
    line,
    col,
    prev,
    /* CCA */body.slice(start ...  position));
}

/**
 * Returns the new position in the source after reading digits.
 */
private function readDigits(source:Source, start, firstCode) {
  var body = source/* source.body */;
  var position = start;
  var code = firstCode;
  if (code >= 48 && code <= 57) {
    // 0 - 9
    do {
      code = /* CCA */source.fastGet(++position);
    } while (code >= 48 && code <= 57); // 0 - 9
    return position;
  }
  throw syntaxError(
    source,
    position,
    'Invalid number, expected digit but got: ${printCharCode(code)}.');
}

/**
 * Reads a string token from the source file.
 *
 * "([^"\\\u000A\u000D]|(\\(u[0-9a-fA-F]{4}|["\\/bfnrt])))*"
 */
private function readString(source:Source, start, line, col, prev): Token {
  var body = source/* source.body */;
  var position = start + 1;
  var chunkStart = position;
  var code = 0;
  var value = '';

  while (
    position < body.length &&
    (code = /* CCA */source.fastGet(position)) != null &&
    // not LineTerminator
    code != 0x000a &&
    code != 0x000d
  ) {
    // Closing Quote (")
    if (code == 34) {
      value += /* CCA */body.slice(chunkStart ...  position);
      return TokUtil.asToken(
        TokenKind.STRING,
        start,
        position + 1,
        line,
        col,
        prev,
        value);
    }

    // SourceCharacter
    if (code < 0x0020 && code != 0x0009) {
      throw syntaxError(
        source,
        position,
        'Invalid character within String: ${printCharCode(code)}.');
    }

    ++position;
    if (code == 92) {
      // \
      value += /* CCA */body.slice(chunkStart ...  position - 1);
      code = /* CCA */source.fastGet(position);
      switch (code) {
        case 34:
          value += '"';
          /* brcaseeak; */
        case 47:
          value += '/';
          /* brcaseeak; */
        case 92:
          value += '\\';
          /* brcaseeak; */
        case 98:
          value += '\u0008' /* backspace? Haxe doesnt like \b */;
          /* brcaseeak; */
        case 102:
          value += '\u000C' /* form feed? Haxe doesnt like \f */;
          /* brcaseeak; */
        case 110:
          value += '\n';
          /* brcaseeak; */
        case 114:
          value += '\r';
          /* brcaseeak; */
        case 116:
          value += '\t';
          /* brcaseeak; */
        case 117: // u
          var charCode = uniCharCode(
            /* CCA */source.fastGet(position + 1),
            /* CCA */source.fastGet(position + 2),
            /* CCA */source.fastGet(position + 3),
            /* CCA */source.fastGet(position + 4));
          if (charCode < 0) {
            throw syntaxError(
              source,
              position,
              'Invalid character escape sequence: ' +
                '\\u${body.slice(position + 1 ...  position + 5)}.');
          }
          value += String.fromCharCode(charCode);
          position += 4;
          /* brdefaulteak; */
        default:
          throw syntaxError(
            source,
            position,
            'Invalid character escape sequence: ${String.fromCharCode(code)}.');
      }
      ++position;
      chunkStart = position;
    }
  }

  throw syntaxError(source, position, 'Unterminated string.');
}

/**
 * Reads a block string token from the source file.
 *
 * """("?"?(\\"""|\\(?!=""")|[^"\\]))*"""
 */
private function readBlockString(source:Source, start, line, col, prev): Token {
  var body = source/* source.body */;
  var position = start + 3;
  var chunkStart = position;
  var code = 0;
  var rawValue = '';

  while (
    position < body.length &&
    (code = /* CCA */source.fastGet(position)) != null
  ) {
    // Closing Triple-Quote (""")
    if (
      code == 34 &&
      /* CCA */source.fastGet(position + 1) == 34 &&
      /* CCA */source.fastGet(position + 2) == 34
    ) {
      rawValue += /* CCA */body.slice(chunkStart ...  position);
      return TokUtil.asToken(
        TokenKind.BLOCK_STRING,
        start,
        position + 3,
        line,
        col,
        prev,
        { throw 'TODO: implement blockStringValue(rawValue)'; null; });
    }

    // SourceCharacter
    if (
      code < 0x0020 &&
      code != 0x0009 &&
      code != 0x000a &&
      code != 0x000d
    ) {
      throw syntaxError(
        source,
        position,
        'Invalid character within String: ${printCharCode(code)}.');
    }

    // Escape Triple-Quote (\""")
    if (
      code == 92 &&
      /* CCA */source.fastGet(position + 1) == 34 &&
      /* CCA */source.fastGet(position + 2) == 34 &&
      /* CCA */source.fastGet(position + 3) == 34
    ) {
      rawValue += /* CCA */body.slice(chunkStart ...  position) + '"""';
      position += 4;
      chunkStart = position;
    } else {
      ++position;
    }
  }

  throw syntaxError(source, position, 'Unterminated string.');
}

/**
 * Converts four hexidecimal chars to the integer that the
 * string represents. For example, uniCharCode('0','0','0','f')
 * will return 15, and uniCharCode('0','0','f','f') returns 255.
 *
 * Returns a negative number on error, if a char was invalid.
 *
 * This is implemented by noting that char2hex() returns -1 on error,
 * which means the result of ORing the char2hex() will also be negative.
 */
private function uniCharCode(a, b, c, d) {
  return (
    (char2hex(a) << 12) | (char2hex(b) << 8) | (char2hex(c) << 4) | char2hex(d)
  );
}

/**
 * Converts a hex character to its integer value.
 * '0' becomes 0, '9' becomes 9
 * 'A' becomes 10, 'F' becomes 15
 * 'a' becomes 10, 'f' becomes 15
 *
 * Returns -1 on error.
 */
private function char2hex(a) {
  return a >= 48 && a <= 57
    ? a - 48 // 0-9
    : a >= 65 && a <= 70
      ? a - 55 // A-F
      : a >= 97 && a <= 102
        ? a - 87 // a-f
        : -1;
}

/**
 * Reads an alphanumeric + underscore name from the source.
 *
 * [_A-Za-z][_0-9A-Za-z]*
 */
private function readName(source:Source, start, line, col, prev): Token {
  var body = source/* source.body */;
  var bodyLength = body.length;
  var position = start + 1;
  var code = 0;
  while (
    position != bodyLength &&
    (code = /* CCA */source.fastGet(position)) != null &&
    (code == 95 || // _
    (code >= 48 && code <= 57) || // 0-9
    (code >= 65 && code <= 90) || // A-Z
      (code >= 97 && code <= 122)) // a-z
  ) {
    ++position;
  }
  return TokUtil.asToken(
    TokenKind.NAME,
    start,
    position,
    line,
    col,
    prev,
    /* CCA */body.slice(start ...  position));
}


private function syntaxError(source:Source, start:Int, msg:String) {
  return ( { message:msg, pos:{ file:null, min:start, max:start } } : graphql.parser.Parser.Err );
}



} // end of class Lexer

class TokUtil {
public static function asToken(kind: TokenKindEnum,
  start:Int /* number */,
  end:Int /* number */,
  line:Int /* number */,
  column:Int /* number */,
  prev: Null<Token>,
  ?value:String):Token
  {
    return {
      kind:kind,
      start:start,
      end:end,
      line:line,
      column:column,
      value:value,
      prev:prev,
      next:null
    }
  }
}
