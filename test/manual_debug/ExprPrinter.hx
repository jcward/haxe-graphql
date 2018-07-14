package;

import haxe.macro.Expr;

class Test
{
  public static function main()
  {
    trace('Hello');
    var p = new MyPrinter();
    var ct:ComplexType = macro :{ a:String, ?b:Int };

    // TAnonymous([{ kind => FVar(TPath({ name => String, pack => [], params => [] }),null), name => a, pos => { file => Test.hx, max => 184, min => 176 } },{ kind => FVar(TPath({ name => Int, pack => [], params => [] }),null), meta => [{ name => :optional, params => [], pos => { file => ?, max => -1, min => -1 } }], name => b, pos => { file => Test.hx, max => 192, min => 187 } }])
    trace(ct);

    // { var a : String; @:optional var b : Int; }
    trace( p.printComplexType( ct ));
  }
}

class MyPrinter extends haxe.macro.Printer
{
  public function new() super();

	override public function printComplexType(ct:ComplexType) return switch(ct) {
		case TPath(tp): printTypePath(tp);
		case TFunction(args, ret):
			function printArg(ct) return switch ct {
				case TFunction(_): "(" + printComplexType(ct) + ")";
				default: printComplexType(ct);
			};
			(args.length>0 ? args.map(printArg).join(" -> ") :"Void") + " -> " + printComplexType(ret);
		case TAnonymous(fields):
      var rtn = "{ " + [for (f in fields) printField(f) + ", "].join("") + "}";
      rtn;
		case TParent(ct): "(" + printComplexType(ct) + ")";
		case TOptional(ct): "?" + printComplexType(ct);
		case TExtend(tpl, fields): '{> ${tpl.map(printTypePath).join(" >, ")}, ${fields.map(printField).join(", ")} }';
	}

	override public function printField(field:Field) {
    var is_optional:Bool = (field.meta != null && field.meta.length > 0) ? (' '+field.meta.map(printMetadata).join(" ")+' ').indexOf(' @:optional ')>=0 : false;
    return switch(field.kind) {
		  case FVar(t, eo): '${ is_optional ? "?" : "" }${field.name}' + opt(t, printComplexType, ":");
      default: throw 'I only handle FVars!';
		}
  }

}
