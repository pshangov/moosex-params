use strict;
use warnings;

use Test::Most;
use MooseX::Params::Util;

my $signature = "number?, :simple, :complex!, string, *test";

my @expected = (
    # number?
    {
        name     => "number",
        required => 0,
        type     => "positional",
        slurpy   => 0,
    },
    # :simple
    {
        name     => "simple",
        required => 0,
        type     => "named",
        slurpy   => 0,
    },
    # :complex
    {
        name     => "complex",
        required => 1,
        type     => "named",
        slurpy   => 0,
    },
    # string
    {
        name     => "string",
        required => 1,
        type     => "positional",
        slurpy   => 0,
    },
    # &test
    {
        name     => "test",
        required => 1,
        type     => "positional",
        slurpy   => 1,
    },
);

subtest 'function signatures' => sub {
    my @specs = MooseX::Params::Util::parse_function_proto($signature);
    is_deeply(\@specs, \@expected, "parameter specifications");
};

subtions 'method signatures with implicit self' => sub {
    my @specs = MooseX::Params::Util::parse_method_proto($signature);
    is(@specs, 6, "number of parameters");
};

subtions 'method signatures with explicit self' => sub {
    my @specs = MooseX::Params::Util::parse_method_proto("self: " . $signature);

    my $invocant = {
        name     => 'self',
        required => 1,
        type     => 'positional',
        slurpy   => 0
    };

    is_deeply(\@specs, [$invocant, @expected], "parameter specifications");
};
done_testing;
