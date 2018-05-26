package graphql.parser;

class Test
{
  public static macro function test(val:String):haxe.macro.Expr
  {
    // Ensure we can run this at macro-time:
    try {
      var result = new GQLParser(byte.ByteData.ofString(val), "SomeGQLInput");
      return macro $v{ result.parseGraphQL() };
    } catch (e:Dynamic) {
      trace('GraphQL parse failed:');
      trace(e);
      trace(Reflect.field(e, "pos"));
    }
    return macro null;
  }

  public static function main()
  {
    var obj = test(' enum Episode { THIS THAT OTHER } ');
    trace(obj);
  }
}
