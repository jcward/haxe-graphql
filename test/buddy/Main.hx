import buddy.*;
using buddy.Should;

class Main implements Buddy<[
                             tests.basic.BasicTypes,
                             tests.basic.ValidHaxe,
                             tests.basic.Reporting,
                             tests.basic.BasicSchema,
                             tests.args.ArgsDefaultValues,
                             tests.operations.BasicQuery,
                             tests.operations.ArgsQuery,
                             tests.operations.QueryTypeGeneration,
                             tests.operations.MutationTypeGeneration,
                             tests.operations.UnnamedQuery,
                             tests.star_wars.StarWarsTest
]> {}
