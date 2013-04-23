use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use MooseX::Params::Signatures;

    method test => sub (first) {
        $_{first}
    };

    annotate test => (
        buildargs => '_buildargs_test'
    );

    sub _buildargs_test { shift, 42 }

    
    method test_fail => sub (first) {
        $_{first}
    };

    annotate test_fail => (
        checkargs => '_checkargs_test_fail'
    );

    sub _checkargs_test_fail { die unless $_{first} > 30 }
}

my $object = TestExecute->new;

is($object->test(24), 42, 'buildargs');
dies_ok { $object->test_fail(24) } 'checkargs dies';
lives_ok { $object->test_fail(42) } 'checkargs lives';

done_testing;
