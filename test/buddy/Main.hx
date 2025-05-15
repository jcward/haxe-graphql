import buddy.*;

import buddy.reporting.ConsoleColorReporter;

class Main {
  public static function main()
  {

    var reporter = new ConsoleColorReporter();

    var runner = new buddy.SuitesRunner([
                             // Basic functional and smoke tests
                             new tests.basic.BasicTypes(),
                             new tests.basic.BasicErrors(),
                             new tests.basic.BoolTest(),
                             new tests.basic.Interfaces(),
                             new tests.basic.ValidHaxe(),
                             new tests.basic.Reporting(),
                             new tests.basic.BasicSchema(),
                             new tests.basic.CovarianceUnion(),
                             new tests.basic.CovarianceInterface(),
                             new tests.args.ArgsDefaultValues(),
                             new tests.args.ArgsBlockString(),
                             new tests.operations.BasicQuery(),
                             new tests.operations.ArgsQuery(),
                             new tests.operations.QueryTypeGeneration(),
                             new tests.operations.MutationTypeGeneration(),
                             new tests.operations.UnnamedQuery(),
                             new tests.operations.VerifyDirectives(),
                             new tests.star_wars.StarWarsTest(),

                             new tests.fragments.FragmentTest(),
                             new tests.fragments.Collapse(),
                             new tests.fragments.Unreachable(),
                             new tests.fragments.EmptyFragment(),

                             new tests.extend.TypeExtend(),
                             new tests.extend.TypeExtendErrors(),

                             // Github issue testcases
                             new tests.issues.Issue23(),
                             new tests.issues.Issue27(),
                             new tests.issues.Issue30(),
                             new tests.issues.Issue31(),
                             new tests.issues.Issue35(),
                             new tests.issues.Issue43(),
                             new tests.issues.Issue43b(),
                             new tests.issues.Issue48(),
    ], reporter);

    runner.run();

#if COVERAGE
    var coverage = coverme.Logger.instance.getCoverage();
    HtmlReport.report(coverage, "coverage");
#end

    #if sys
      Sys.exit(runner.statusCode());
    #end
  }

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