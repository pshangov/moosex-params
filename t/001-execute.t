use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use MooseX::Params;

    method 'test_only'     => sub { 'OK' };
    method 'test_trailing' => ( params  => ['any'], sub { 'OK' } );
    method 'test_execute'  => ( execute => sub { 'OK' } );
    method 'test_string'   => ( execute => '_execute_test_string' );

    method 'test_default';
    method 'test_default_with_options' => ( params => ['any'] );

    sub _execute_test_string  { 'OK' }
    sub _execute_test_default { 'OK' }
    sub _execute_test_default_with_options { 'OK' }

    no MooseX::Params;
}

my $object = TestExecute->new;

foreach my $test (qw(test_only test_trailing test_execute test_string test_default test_default_with_options))
{
    is($object->$test, 'OK', $test);
}

done_testing();
