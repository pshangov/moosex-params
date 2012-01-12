use strict;
use warnings;

use Test::Most;

use MooseX::Params;

my $sub = sub :Args(Int first) { 10 };

is ( $sub->(42), 42, 'function call' );
dies_ok { $sub->([42]) } 'validation';

done_testing;
