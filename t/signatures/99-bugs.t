use strict;
use warnings;

use Test::Most;
use MooseX::Params::Signatures;

function foo => sub (bar, baz) { $_{baz} };
validate foo => ( baz => { builder => '_build_baz' } );
sub _build_baz { 2 }

lives_ok ( sub { foo(1) }, "parameter builder wrapper with Moose 2.0401" );

done_testing;
