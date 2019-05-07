package;

import js.html.*;
// import js.Browser.*;
// import js.jquery.Helper.J as JQ;

@:expose
class Demo
{
  public static function main()
  {
  }

  @:keep
  public static function parse(source:String):graphql.ASTDefs.DocumentNode
  {
    // noLocation allows JSON printing
    var p = new graphql.parser.Parser(source, { noLocation:true });
    return p.document;
  }

  @:keep
  public static function hxgen(doc:graphql.ASTDefs.DocumentNode):{ stderr:String, stdout:String }
  {
    return graphql.HaxeGenerator.parse(doc);
  }
}
