use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Params::Signatures;

    # test_isa

    method test_isa => sub (self: first) { $_{first} };

    validate test_isa => (
        first => { isa => 'Int' },
    );

    # test_required

    method test_required => sub (self: first) { $_{first} };

    # test_slurpy

    method test_slurpy => sub (join, *all) {
        join $_{join}, @{$_{all}}
    };

    validate test_slurpy => (
        join => { isa => 'Str' },
        all  => { isa => 'ArrayRef[Int]' },
    );

    # test_transform

    subtype 'ArrayRefOfInt' => as 'ArrayRef[Int]';

    coerce 'ArrayRefOfInt'
        => from 'Int'
        => via { [ $_ ] };

    method test_transform => sub (self: first, second, third) {
        @_{qw(first second third)}
    };

    validate test_transform => (
        first  => { isa => 'ArrayRefOfInt', coerce => 1 },
        second => { isa => 'ArrayRefOfInt' },
        third  => { isa => 'ArrayRefOfInt', default => sub { [42] } },
    );
}

my $object = TestExecute->new;

lives_ok { $object->test_isa(5)      } 'isa ok';
dies_ok  { $object->test_isa('Five') } 'isa fail';
lives_ok { $object->test_required(5) } 'required ok';
dies_ok  { $object->test_required()  } 'required fail';

is($object->test_slurpy('-', qw(1 2 3)), '1-2-3', 'slurpy');

my ($first, $second, $third) = $object->test_transform(42, [42]);

is($$first[0], 42, 'coerce');
is($$third[0], 42, 'default');

done_testing();

