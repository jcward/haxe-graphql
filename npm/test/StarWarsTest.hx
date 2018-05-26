class StarWarsTest {
  public static function main()
  {
    var droid:GQLTypes.Droid = { id:'123', name:'R2-D2', friendsConnection:null, appearsIn:null };
    var human:GQLTypes.Human = { id:'123', name:'Luke Skywalker', friendsConnection:null, appearsIn:null, height:1.8 };
    var char:GQLTypes.Character = droid;
    char = human;
    trace(char);
    var nm:GQLTypes.IName = droid;
  }
}
