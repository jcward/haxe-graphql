// ported by hand, based on: https://raw.githubusercontent.com/graphql/graphql-js/v14.3.0/src/language/blockString.js
package graphql.parser;

using StringTools;

class BlockStringUtil {
	public static function dedentBlockStringValue(rawString:String):String {
		// Expand a block string's raw value into independent lines.

		// The EReg approach does not work, eats extra spaces:
		var linesReg = ~/\r\n|[\n\r]/g;
		var lines = linesReg.split(rawString);
/*
		var lines = [];
		for (l1 in rawString.split("\r\n")) {
			for (l2 in l1.split("\n")) {
				for (l3 in l2.split("\r")) lines.push(l3);
			}
		}
*/
		// Remove common indentation from all lines but first.
		var commonIndent = getBlockStringIndentation(lines);

		if (commonIndent != 0) {
			for (i in 1...lines.length) {
				lines[i] = lines[i].substr(commonIndent);
			}
		}

		// Remove leading and trailing blank lines.
		while (lines.length > 0 && isBlank(lines[0])) {
			lines.shift();
		}
		while (lines.length > 0 && isBlank(lines[lines.length - 1])) {
			lines.pop();
		}

		// Return a string of the lines joined with U+000A.
		return lines.join('\n');
	}

	// @internal
	public static function getBlockStringIndentation(lines:Array<String>):Int {
		var commonIndent:Null<Int> = null;

		for (i in 1...lines.length) {
			var line = lines[i];
			var indent = leadingWhitespace(line);
			if (indent == line.length) {
				continue; // skip empty lines
			}

			if (commonIndent == null || indent < commonIndent) {
				commonIndent = indent;
				if (commonIndent == 0) {
					break;
				}
			}
		}

		return commonIndent == null ? 0 : commonIndent;
	}

	private static function leadingWhitespace(str:String) {
		var i = 0;
		while (i < str.length && (str.charCodeAt(i)==32 || str.charCodeAt(i)==9)) {
			i++;
		}
		return i;
	}

	private static function isBlank(str) {
		return leadingWhitespace(str) == str.length;
	}

	/**
	 * Print a block string in the indented block form by adding a leading and
	 * trailing blank line. However, if a block string starts with whitespace and is
	 * a single-line, adding a leading blank line would strip that whitespace.
	 */
	public static function printBlockString(value:String, indentation:String = '', preferMultipleLines:Bool = false):String {
		var isSingleLine = value.indexOf('\n') == -1;
		var hasLeadingSpace = value.substr(0,1) == ' ' || value.substr(0,1) == '\t';
		var hasTrailingQuote = value.substring(value.length - 1) == '"';
		var printAsMultipleLines = !isSingleLine || hasTrailingQuote || preferMultipleLines;

		var result = '';
		// Format a multi-line block quote to account for leading space.
		if (printAsMultipleLines && !(isSingleLine && hasLeadingSpace)) {
			result += '\n' + indentation;
		}
		var re = ~/\n/g;
		if (indentation != '' && re.match(value)) {
			value = re.map(value, function(r) {
				return '\n' + indentation;
			});
			result += value;
		} else {
			result += value;
		}
		//   result += indentation ? value.replace(/\n/g, '\n' + indentation) : value;
		if (printAsMultipleLines) {
			result += '\n';
		}
		var reg = ~/"""/g;
		if (reg.match(result)) {
			result = reg.map(result, function(r) {
				return '\\"""';
			});
		}
		return '"""' + result + '"""';
	}
}
