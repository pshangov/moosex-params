use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(isweak);

{
    package TestExecute;

    use MooseX::Params;
    use Moose::Util::TypeConstraints;

    method 'test_isa' =>
    (
        params => [ 'first' => { isa => 'Int'} ],
        sub { $_{first} }
    );

    method 'test_required' =>
    (
        params => [ 'first' => { required => 1 } ],
        sub { $_{first} }
    );

    subtype 'ArrayRefOfInt' => as 'ArrayRef[Int]';

    coerce 'ArrayRefOfInt'
        => from 'Int'
        => via { [ $_ ] };

    method 'test_transform' =>
    (
        params =>
        [
            first  => { isa => 'ArrayRefOfInt', coerce   => 1 },
            second => { isa => 'ArrayRefOfInt', weak_ref => 1 },
            third  => { isa => 'ArrayRefOfInt', default  => sub { [42] } },
        ],
        sub { @_{qw(first second third)} }
    );

    no MooseX::Params;
}

my $object = TestExecute->new;

lives_ok { $object->test_isa(5)      } 'isa ok';
dies_ok  { $object->test_isa('Five') } 'isa fail';
lives_ok { $object->test_isa(5)      } 'required ok';
dies_ok  { $object->test_isa()       } 'required fail';

my ($first, $second, $third) = $object->test_transform(42, [42]);

is($$first[0], 42, 'coerce ok');
#ok(isweak($second), 'weakref ok');
is($$third[0], 42, 'default ok');

done_testing();
