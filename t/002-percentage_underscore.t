use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use MooseX::Params;

    method 'test', params => [qw(first)], sub { "$_{first} is first!" };

    no MooseX::Params;
}

my $object = TestExecute->new;
my $result = $object->test('George');

is($result, 'George is first!', 'percentage underscore inflation');

done_testing();
