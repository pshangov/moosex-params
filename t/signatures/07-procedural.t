use strict;
use warnings;

use Test::Most;

use MooseX::Params::Signatures;

function test => sub (first) { $_{first} };

validate test => ( first => { isa => 'Int' } );

is (test(42), 42, 'function call');
dies_ok { test([42]) } 'validation';

done_testing;
