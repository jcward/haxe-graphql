package graphql.parser;

using StringTools;

class BlockStringUtil {
	public static function dedentBlockStringValue(rawString:String):String {
		// Expand a block string's raw value into independent lines.
		var linesReg = ~/\r\n|[\n\r]/g;
		linesReg.match(rawString);
		var lines = [];
		linesReg.map(rawString, function(r) {
			var m = r.matched(0);
			lines.push(m);
			return rawString;
		});
		//   var lines = rawString.split(/\r\n|[\n\r]/g);

		// Remove common indentation from all lines but first.
		var commonIndent = getBlockStringIndentation(lines);

		if (commonIndent != 0) {
			for (i in 1...lines.length) {
                var sl = new StringSlice(lines[i], 0, lines[i].length);
                var ite = new IntIterator(0, commonIndent);
                
				lines[i] = sl.slice(ite).toString();
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
		var commonIndent:Int = null;

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
		while (i < str.length && (str.substring(i) == ' ' || str.substring(i) == '\t')) {
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
		var hasLeadingSpace = value.substring(0) == ' ' || value.substring(0) == '\t';
		var hasTrailingQuote = value.substring(value.length - 1) == '"';
		var printAsMultipleLines = !isSingleLine || hasTrailingQuote || preferMultipleLines;

		var result = '';
		// Format a multi-line block quote to account for leading space.
		if (printAsMultipleLines && !(isSingleLine && hasLeadingSpace)) {
			result += '\n' + indentation;
		}
		var re = ~/\n/g;
		if (indentation != '' && re.match(value)) {
			value = re.map(value, (r) -> {
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
