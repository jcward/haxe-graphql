import buddy.*;
using buddy.Should;

class Main implements Buddy<[
                             // Basic functional and smoke tests
                             tests.basic.BasicTypes,
                             tests.basic.BoolTest,
                             tests.basic.ValidHaxe,
                             tests.basic.Reporting,
                             tests.basic.BasicSchema,
                             tests.basic.CovarianceUnion,
                             tests.basic.CovarianceInterface,
                             tests.args.ArgsDefaultValues,
                             tests.operations.BasicQuery,
                             tests.operations.ArgsQuery,
                             tests.operations.QueryTypeGeneration,
                             tests.operations.MutationTypeGeneration,
                             tests.operations.UnnamedQuery,
                             tests.star_wars.StarWarsTest,

                             tests.fragments.FragmentTest,
                             tests.fragments.Collapse,
                             tests.fragments.Unreachable,
                             tests.fragments.EmptyFragment,

                             // Github issue testcases
                             tests.issues.Issue23,
                             tests.issues.Issue27,
]> {

  public static function find_type_in_code(code:String, type:String):String
  {
    var result = '';
    var capture = false;
    for (line in code.split("\n")) {
      if (line.indexOf(type)>=0) capture = true;
      if (capture==true && line=='}') { capture = false; break; }
      if (capture) result += line + "\n";
    }
    return result;
  }

  public static function print(msg:String, color=MAGENTA)
  {
    Sys.println(color + msg + DEFAULT);
  }
}

@:enum abstract Color(String) {
	var DEFAULT = '\033[0m';
	var BLACK   = '\033[0;30m';
	var RED     = '\033[31m';
	var GREEN   = '\033[32m';
	var YELLOW  = '\033[33m';
	var BLUE    = '\033[1;34m';
	var GRAY    = '\033[0;37m';
	var MAGENTA = '\033[1;35m';
	var CYAN    = '\033[0;36m';
	var WHITE   = '\033[1;37m';
}