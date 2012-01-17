use strict;
use warnings;

use Test::Most;
use MooseX::Params;

sub foo :Args(bar) :Returns(Str) { 'baz' }
sub crash :Returns(Str) { ['boom'] }

is foo('bar'),   'baz',  "returns with signature";
dies_ok { crash('bar') } "returns without signature";

done_testing;
