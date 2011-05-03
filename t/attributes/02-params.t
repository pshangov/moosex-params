use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Params::Interface::Attributes;

    sub test_isa :Args(Int first) { $_{first} }

    sub test_required :Args(first) { $_{first} }

    subtype 'ArrayRefOfInt' => as 'ArrayRef[Int]';

    coerce 'ArrayRefOfInt'
        => from 'Int'
        => via { [ $_ ] };

    sub test_transform
        :Args(&ArrayRefOfInt first, ArrayRefOfInt second, ArrayRefOfInt third = _build_param_third)
    {
        @_{qw(first second third)}
    }

    sub _build_param_third { [42] }
}

my $object = TestExecute->new;

lives_ok { $object->test_isa(5)      } 'isa ok';
dies_ok  { $object->test_isa('Five') } 'isa fail';
lives_ok { $object->test_isa(5)      } 'required ok';
dies_ok  { $object->test_isa()       } 'required fail';

my ($first, $second, $third) = $object->test_transform(42, [42]);

is($$first[0], 42, 'coerce ok');
is($$third[0], 42, 'default ok');

done_testing();

