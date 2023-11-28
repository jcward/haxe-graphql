/*
 * Copyright (C)2005-2017 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package graphql;

import haxe.macro.Expr;
using Lambda;
using StringTools;

/**
	This class provides some utility methods to convert elements from the
	macro context to a human-readable String representation.
*/
class CustomPrinter {
	var tabs:String;
	var tabString:String;
	var fieldDelimiter:String;
	var shortTypedefs:Bool;

	public function new(?tabString = "\t",
                      shortTypedefs=false) {
		tabs = "";
    fieldDelimiter = shortTypedefs ? ',' : ';';
    this.shortTypedefs = shortTypedefs;
		this.tabString = tabString;
	}

	public function printUnop(op:Unop) return switch(op) {
		case OpIncrement: "++";
		case OpDecrement: "--";
		case OpNot: "!";
		case OpNeg: "-";
		case OpNegBits: "~";
		#if (haxe >= "4.2")
		case OpSpread: "...";
		#end
	}

	public function printBinop(op:Binop) return switch(op) {
		case OpAdd: "+";
		case OpMult: "*";
		case OpDiv: "/";
		case OpSub: "-";
		case OpAssign: "=";
		case OpEq: "==";
		case OpNotEq: "!=";
		case OpGt: ">";
		case OpGte: ">=";
		case OpLt: "<";
		case OpLte: "<=";
		case OpAnd: "&";
		case OpOr: "|";
		case OpXor: "^";
		case OpBoolAnd: "&&";
		case OpBoolOr: "||";
		case OpShl: "<<";
		case OpShr: ">>";
		case OpUShr: ">>>";
		case OpMod: "%";
		case OpInterval: "...";
		case OpArrow: "=>";
		#if (haxe_ver >= 4.000) 
		case OpIn: "in";
		#end
		#if (haxe >= "4.3")
		case OpNullCoal: "?.";
		#end
		case OpAssignOp(op):
			printBinop(op)
			+ "=";
	}

	function escapeString(s:String,delim:String) {
		return delim + s.replace("\n","\\n").replace("\t","\\t").replace("'","\\'").replace('"',"\\\"") #if sys .replace("\x00","\\x00") #end + delim;
	}

	public function printFormatString(s:String) {
		return escapeString(s,"'");
	}

	public function printString(s:String) {
		return escapeString(s,'"');
	}

	public function printConstant(c:Constant) return switch(c) {
		case CString(s): printString(s);
		case CIdent(s),
			CInt(s),
			CFloat(s):
				s;
		case CRegexp(s,opt): '~/$s/$opt';
	}

	public function printTypeParam(param:TypeParam) return switch(param) {
		case TPType(ct): printComplexType(ct);
		case TPExpr(e): printExpr(e);
	}

	public function printTypePath(tp:TypePath) return
		(tp.pack.length > 0 ? tp.pack.join(".") + "." : "")
		+ tp.name
		+ (tp.sub != null ? '.${tp.sub}' : "")
		+ (tp.params == null ? "" : tp.params.length > 0 ? "<" + tp.params.map(printTypeParam).join(", ") + ">" : "");

	// TODO: check if this can cause loops
	public function printComplexType(ct:ComplexType) return switch(ct) {
		case TPath(tp): printTypePath(tp);
		case TFunction(args, ret):
			function printArg(ct) return switch ct {
				case TFunction(_): "(" + printComplexType(ct) + ")";
				default: printComplexType(ct);
			};
			(args.length>0 ? args.map(printArg).join(" -> ") :"Void") + " -> " + printComplexType(ret);
		case TAnonymous(fields): "{ " + [for (f in fields) printField(f) + fieldDelimiter+" "].join("") + "}";
		case TParent(ct): "(" + printComplexType(ct) + ")";
		case TOptional(ct): "?" + printComplexType(ct);
		case TNamed(n, ct): n + ":" + printComplexType(ct);
		case TExtend(tpl, fields): '{> ${tpl.map(printTypePath).join(" >, ")}, ${fields.map(printField).join(", ")} }';
		case TIntersection(tl): tl.map(printComplexType).join(" & ");
	}

	public function printMetadata(meta:MetadataEntry) return
		'@${meta.name}'
		+ ((meta.params != null && meta.params.length > 0) ? '(${printExprs(meta.params,", ")})' : "");

	public function printAccess(access:Access) return switch(access) {
		case AStatic: "static";
		case APublic: "public";
		case APrivate: "private";
		case AOverride: "override";
		case AInline: "inline";
		case ADynamic: "dynamic";
		case AMacro: "macro";
		#if (haxe_ver >= 4.000) 
		case AExtern: "extern";
		case AFinal: "final";
		#end
		#if (haxe >= "4.2")
		case AOverload: "/* overload? */";
		case AAbstract: "/* abstract? */";
		#end
	}

	public function printField(field:Field) {
    var as_short = shortTypedefs && switch(field.kind) {
		  case FVar(_): true;
      default: false;
    }

    var is_optional:Bool = field.meta != null && field.meta.length > 0 && field.meta.exists(function(m) return m.name==':optional');
    var meta = field.meta.filter(function(m) return as_short && m.name!=':optional');
    var preamble = (field.doc != null && field.doc != "" ? "/**\n" + tabs + tabString + StringTools.replace(field.doc, "\n", "\n" + tabs + tabString) + "\n" + tabs + "**/\n" + tabs : "")
		+ (meta != null && meta.length > 0 ? meta.map(printMetadata).join('\n$tabs') + '\n$tabs' : "")
		+ (field.access != null && field.access.length > 0 ? field.access.map(printAccess).join(" ") + " " : "");

    return preamble + switch(field.kind) {
		  case FVar(t, eo):
		    if (shortTypedefs) {
          '${ is_optional ? "?" : ""}${field.name}' + opt(t, printComplexType, " : ") + opt(eo, printExpr, " = ");
        } else {
          'var ${field.name}' + opt(t, printComplexType, " : ") + opt(eo, printExpr, " = ");
        }
		  case FProp(get, set, t, eo): 'var ${field.name}($get, $set)' + opt(t, printComplexType, " : ") + opt(eo, printExpr, " = ");
		  case FFun(func): 'function ${field.name}' + printFunction(func);
		}
  }

	public function printTypeParamDecl(tpd:TypeParamDecl) return
		tpd.name
		+ (tpd.params != null && tpd.params.length > 0 ? "<" + tpd.params.map(printTypeParamDecl).join(", ") + ">" : "")
		+ (tpd.constraints != null && tpd.constraints.length > 0 ? ":(" + tpd.constraints.map(printComplexType).join(", ") + ")" : "");

	public function printFunctionArg(arg:FunctionArg) return
		(arg.opt ? "?" : "")
		+ arg.name
		+ opt(arg.type, printComplexType, ":")
		+ opt(arg.value, printExpr, " = ");

	public function printFunction(func:Function) return
		(func.params == null ? "" : func.params.length > 0 ? "<" + func.params.map(printTypeParamDecl).join(", ") + ">" : "")
		+ "(" + func.args.map(printFunctionArg).join(", ") + ")"
		+ opt(func.ret, printComplexType, ":")
		+ opt(func.expr, printExpr, " ");

	public function printVar(v:Var) return
		v.name
		+ opt(v.type, printComplexType, ":")
		+ opt(v.expr, printExpr, " = ");


	public function printExpr(e:Expr) return e == null ? "#NULL" : switch(e.expr) {
		#if (macro && !display)
		case EConst(CString(s)): haxe.macro.MacroStringTools.isFormatExpr(e) ? printFormatString(s) : printString(s);
		#end
		case EConst(c): printConstant(c);
		case EArray(e1, e2): '${printExpr(e1)}[${printExpr(e2)}]';
		case EBinop(op, e1, e2): '${printExpr(e1)} ${printBinop(op)} ${printExpr(e2)}';
		case EField(e1, n): '${printExpr(e1)}.$n';
		case EParenthesis(e1): '(${printExpr(e1)})';
		case EObjectDecl(fl):
			"{ " + fl.map(function(fld) return '${fld.field} : ${printExpr(fld.expr)}').join(", ") + " }";
		case EArrayDecl(el): '[${printExprs(el, ", ")}]';
		case ECall(e1, el): '${printExpr(e1)}(${printExprs(el,", ")})';
		case ENew(tp, el): 'new ${printTypePath(tp)}(${printExprs(el,", ")})';
		case EUnop(op, true, e1): printExpr(e1) + printUnop(op);
		case EUnop(op, false, e1): printUnop(op) + printExpr(e1);
		case EFunction(no, func) if (no != null): 'function $no' + printFunction(func);
		case EFunction(_, func): "function" +printFunction(func);
		case EVars(vl): "var " +vl.map(printVar).join(", ");
		case EBlock([]): '{ }';
		case EBlock(el):
			var old = tabs;
			tabs += tabString;
			var s = '{\n$tabs' + printExprs(el, ';\n$tabs');
			tabs = old;
			s + ';\n$tabs}';
		case EFor(e1, e2): 'for (${printExpr(e1)}) ${printExpr(e2)}';
		#if (haxe_ver < 4.000) case EIn(e1, e2): '${printExpr(e1)} in ${printExpr(e2)}'; #end
		case EIf(econd, eif, null): 'if (${printExpr(econd)}) ${printExpr(eif)}';
		case EIf(econd, eif, eelse): 'if (${printExpr(econd)}) ${printExpr(eif)} else ${printExpr(eelse)}';
		case EWhile(econd, e1, true): 'while (${printExpr(econd)}) ${printExpr(e1)}';
		case EWhile(econd, e1, false): 'do ${printExpr(e1)} while (${printExpr(econd)})';
		case ESwitch(e1, cl, edef):
			var old = tabs;
			tabs += tabString;
			var s = 'switch ${printExpr(e1)} {\n$tabs' +
				cl.map(function(c)
					return 'case ${printExprs(c.values, ", ")}'
						+ (c.guard != null ? ' if (${printExpr(c.guard)}):' : ":")
						+ (c.expr != null ? (opt(c.expr, printExpr)) + ";" : ""))
				.join('\n$tabs');
			if (edef != null)
				s += '\n${tabs}default:' + (edef.expr == null ? "" : printExpr(edef) + ";");
			tabs = old;
			s + '\n$tabs}';
		case ETry(e1, cl):
			'try ${printExpr(e1)}'
			+ cl.map(function(c) return ' catch(${c.name}:${printComplexType(c.type)}) ${printExpr(c.expr)}').join("");
		case EReturn(eo): "return" + opt(eo, printExpr, " ");
		case EBreak: "break";
		case EContinue: "continue";
		case EUntyped(e1): "untyped " +printExpr(e1);
		case EThrow(e1): "throw " +printExpr(e1);
		case ECast(e1, cto) if (cto != null): 'cast(${printExpr(e1)}, ${printComplexType(cto)})';
		case ECast(e1, _): "cast " +printExpr(e1);
		#if (haxe >= "4.2")
		case EIs(e1, ct): '${printExpr(e1)} is ${printComplexType(ct)}';
		#end
		case EDisplay(e1, _): '#DISPLAY(${printExpr(e1)})';
		#if (haxe < "4.3")
		case EDisplayNew(tp): '#DISPLAY(${printTypePath(tp)})';
		#end
		case ETernary(econd, eif, eelse): '${printExpr(econd)} ? ${printExpr(eif)} : ${printExpr(eelse)}';
		case ECheckType(e1, ct): '(${printExpr(e1)} : ${printComplexType(ct)})';
		case EMeta(meta, e1): printMetadata(meta) + " " +printExpr(e1);
	}

	public function printExprs(el:Array<Expr>, sep:String) {
		return el.map(printExpr).join(sep);
	}

	function printExtension(tpl:Array<TypePath>, fields: Array<Field>) {
		return '{\n$tabs>' + tpl.map(printTypePath).join(',\n$tabs>') + ","
		    + (fields.length > 0 ? ('\n$tabs' + fields.map(printField).join(';\n$tabs') + ";\n}") : ("\n}"));
	}

	function printStructure(fields:Array<Field>) {
		return fields.length == 0 ? "{ }" :
			'{\n$tabs' + fields.map(printField).join(fieldDelimiter+'\n$tabs') + ";\n}";
	}

	public function printTypeDefinition(t:TypeDefinition, printPackage = true):String {
		var old = tabs;
		tabs = tabString;
		trace(t.name);
		var str = t == null ? "#NULL" :
			(printPackage && t.pack.length > 0 && t.pack[0] != "" ? "package " + t.pack.join(".") + ";\n" : "") +
			(t.meta != null && t.meta.length > 0 ? t.meta.map(printMetadata).join(" ") + " " : "") + (t.isExtern ? "extern " : "") + switch (t.kind) {
				case TDEnum:
					"enum " + t.name + ((t.params != null && t.params.length > 0) ? "<" + t.params.map(printTypeParamDecl).join(", ") + ">" : "") + " {\n"
					+ [for (field in t.fields)
						tabs + (field.doc != null && field.doc != "" ? "/**\n" + tabs + tabString + StringTools.replace(field.doc, "\n", "\n" + tabs + tabString) + "\n" + tabs + "**/\n" + tabs : "")
						+ (field.meta != null && field.meta.length > 0 ? field.meta.map(printMetadata).join(" ") + " " : "")
						+ (switch(field.kind) {
							case FVar(t, _): field.name + opt(t, printComplexType, ":");
							case FProp(_, _, _, _): throw "FProp is invalid for TDEnum.";
							case FFun(func): field.name + printFunction(func);
						}) + ";"
					].join("\n")
					+ "\n}";
				case TDStructure:
					"typedef " + t.name + ((t.params != null && t.params.length > 0) ? "<" + t.params.map(printTypeParamDecl).join(", ") + ">" : "") + " = {\n"
					+ [for (f in t.fields) {
						tabs + printField(f) + fieldDelimiter;
					}].join("\n")
					+ "\n}";
				case TDClass(superClass, interfaces, isInterface):
					(isInterface ? "interface " : "class ") + t.name + (t.params != null && t.params.length > 0 ? "<" + t.params.map(printTypeParamDecl).join(", ") + ">" : "")
					+ (superClass != null ? " extends " + printTypePath(superClass) : "")
					+ (interfaces != null ? (isInterface ? [for (tp in interfaces) " extends " + printTypePath(tp)] : [for (tp in interfaces) " implements " + printTypePath(tp)]).join("") : "")
					+ " {\n"
					+ [for (f in t.fields) {
						tabs + printFieldWithDelimiter(f);
					}].join("\n")
					+ "\n}";
				case TDAlias(ct):
					"typedef " + t.name + ((t.params != null && t.params.length > 0) ? "<" + t.params.map(printTypeParamDecl).join(", ") + ">" : "") + " = "
					+ (switch(ct) {
						case TExtend(tpl, fields): printExtension(tpl, fields);
						case TAnonymous(fields): printStructure(fields);
						case _: printComplexType(ct);
					})
					+ ";";
				case TDAbstract(tthis, from, to):
					"abstract " + t.name
					+ ((t.params != null && t.params.length > 0) ? "<" + t.params.map(printTypeParamDecl).join(", ") + ">" : "")
					+ (tthis == null ? "" : "(" + printComplexType(tthis) + ")")
					+ (from == null ? "" : [for (f in from) " from " + printComplexType(f)].join(""))
					+ (to == null ? "" : [for (t in to) " to " + printComplexType(t)].join(""))
					+ " {\n"
					+ [for (f in t.fields) {
						tabs + printFieldWithDelimiter(f);
					}].join("\n")
					+ "\n}";
				#if (haxe >= "4.2")
				case TDField(kind, access):
					tabs = old;
					(access != null && access.length > 0 ? access.map(printAccess).join(" ") + " " : "")
					+ switch (kind) {
						case FVar(type, eo): ((access != null && access.has(AFinal)) ? '' : 'var ') + '${t.name}' + opt(type, printComplexType, " : ") + opt(eo, printExpr, " = ") + ";";
						case FProp(get, set, type, eo): 'var ${t.name}($get, $set)' + opt(type, printComplexType, " : ") + opt(eo, printExpr, " = ") + ";";
						case FFun(func): 'function ${t.name}' + printFunction(func) + switch func.expr { case {expr: EBlock(_)}: ""; case _: ";"; };
					}

				#end
			}

		tabs = old;
		trace(str);
		return str;
	}

	function printFieldWithDelimiter(f:Field):String
	{
		return printField(f) + switch(f.kind) {
			case FVar(_, _), FProp(_, _, _, _): fieldDelimiter;
			case FFun({expr:null}): fieldDelimiter;
			case FFun({expr:{expr:EBlock(_)}}): "";
			case FFun(_): fieldDelimiter;
			case _: "";
		};
	}

	function opt<T>(v:T, f:T->String, prefix = "") return v == null ? "" : (prefix + f(v));
}
