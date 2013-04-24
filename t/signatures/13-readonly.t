use strict;
use warnings;

use Test::Most;
use MooseX::Params::Signatures;

function helem_create        => sub (foo)      { $_{bar} = 1 };
function helem_assign_simple => sub (foo)      { $_{foo} = 1 };
function helem_assign_alias  => sub (foo)      { $_ = 1 for @{$_{foo}} };
function helem_assign_deep   => sub (foo)      { $_{foo}[2] = 1 };
function helem_iter_alias    => sub (foo)      { 1 for @{$_{foo}} };
function helem_return        => sub (foo)      { @{$_{foo}} };
function hslice_assign       => sub (foo, bar) { @_{qw(foo bar)} = (1, 1) };
function hslice_assign_alias => sub (foo, bar) { $_ = 1 for @_{qw(foo bar)} };
function hslice_iter_alias   => sub (foo, bar) { 1 for @_{qw(foo bar)} };
function hslice_return       => sub (foo, bar) { @_{qw(foo bar)} };

dies_ok  ( sub { helem_create(1) },           "helem create"           );
dies_ok  ( sub { helem_assign_simple(1) },    "helem simple assign"    );
lives_ok ( sub { helem_assign_alias([1,1]) }, "helem assign to alias"  );
lives_ok ( sub { helem_assign_deep([1,1]) },  "helem assign deep"      );
lives_ok ( sub { helem_iter_alias([1,1]) },   "helem iterate"          );
lives_ok ( sub { helem_return([1,1]) },       "helem return values"    );
dies_ok  ( sub { hslice_assign(1,1) },        "hslice assign"          );
dies_ok  ( sub { hslice_assign_alias(1,1) },  "hslice assign to alias" );
lives_ok ( sub { hslice_iter_alias(1,1) },    "hslice iterate"         );
lives_ok ( sub { hslice_return(1,1) },        "hslice return values"   );

done_testing;
