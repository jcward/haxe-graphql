package;

import js.html.*;
import js.Browser.*;
import js.jquery.Helper.J as JQ;

@:expose
class Demo
{
  public static function main()
  {
  }

  @:keep
  public static function parse(source:String):graphql.ASTDefs.Document
  {
    var p = new graphql.parser.Parser(source);
    return p.document;
  }

  @:keep
  public static function hxgen(doc:graphql.ASTDefs.Document):{ stderr:String, stdout:String }
  {
    return graphql.HaxeGenerator.parse(doc);
  }
}
