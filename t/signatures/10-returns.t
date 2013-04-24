use strict;
use warnings;

use Test::Most;
use MooseX::Params::Signatures;

function foo => sub (bar) { 'baz' };
annotate foo => ( returns => 'Str' );

function crash => sub { ['boom'] };
annotate crash => ( returns => 'Str' );

function stuff => sub { qw(foo bar baz) };
annotate stuff => ( returns => 'Array[Str]' );

function stuffref => sub { [qw(foo bar baz)] };
annotate stuffref => ( returns => 'ArrayRef[Str]' );

function dict => sub { foo => 'bar', baz => 'quz' };
annotate dict => ( returns => 'Hash[Str]' );

function dictref => sub { { foo => 'bar', baz => 'quz' } };
annotate dictref => ( returns => 'HashRef[Str]' );

is foo('bar'), 'baz',  "returns with signature";
throws_ok ( sub { crash('bar') }, qr/Validation failed/, "returns without signature" );

my $foo_array = [qw(foo bar baz)];
my $foo_hash  = { foo => 'bar', baz => 'quz' };

my @stuff = stuff();
my $stuffref = stuffref();
my %dict = dict();
my $dictref = dictref();

is_deeply \@stuff, $foo_array, "returns array";
is_deeply $stuffref, $foo_array, "returns arrayref";
is_deeply \%dict, $foo_hash, "returns hash";
is_deeply $dictref, $foo_hash, "returns hashref";

done_testing;
