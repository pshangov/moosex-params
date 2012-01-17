use strict;
use warnings;

use Test::Most skip_all => "dies_ok fails to catch exception";
use MooseX::Params;

dies_ok { my $sub = sub :Args(one) { 1 } } "anonymous sub";

done_testing;
