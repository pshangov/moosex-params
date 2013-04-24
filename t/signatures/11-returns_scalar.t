use strict;
use warnings;

use Test::Most;
use MooseX::Params::Signatures;

function foo_default => sub { qw(foo bar baz) };
annotate foo_default => ( returns => 'Array' );

function foo_first => sub { qw(foo bar baz) };
annotate foo_first => ( returns => 'Array', returns_scalar => 'First' );

function foo_last => sub { qw(foo bar baz) };
annotate foo_last => ( returns => 'Array', returns_scalar => 'Last' );

function foo_arrayref => sub { qw(foo bar baz) };
annotate foo_arrayref => ( returns => 'Array', returns_scalar => 'ArrayRef' );

function foo_count => sub { qw(foo bar baz) };
annotate foo_count => ( returns => 'Array', returns_scalar => 'Count' );

my @res_default  = foo_default();
my @res_first    = foo_first();
my @res_last     = foo_last();
my @res_arrayref = foo_arrayref();
my @res_count    = foo_count();

my $res_default  = foo_default();
my $res_first    = foo_first();
my $res_last     = foo_last();
my $res_arrayref = foo_arrayref();
my $res_count    = foo_count();


my $foo_bar_baz = [qw(foo bar baz)];

is_deeply \@res_default,  $foo_bar_baz, 'default in list context';
is_deeply \@res_first,    $foo_bar_baz, 'first in list context';
is_deeply \@res_last,     $foo_bar_baz, 'last in list context';
is_deeply \@res_arrayref, $foo_bar_baz, 'arrayref in list context';
is_deeply \@res_count,    $foo_bar_baz, 'count in list context';

is        $res_default,   3,            'default in scalar context';
is        $res_first,     'foo',        'first in scalar context';
is        $res_last,      'baz',        'last in scalar context';
is_deeply $res_arrayref,  $foo_bar_baz, 'arrayref in scalar context';
is        $res_count,     3,            'count in scalar context';

done_testing;
