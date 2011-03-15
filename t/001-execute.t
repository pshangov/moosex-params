use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use MooseX::Params;

    warn "Proceeding to method creation";
    
    method 'test_only'     => sub { 'OK' };
    method 'test_trailing' => ( params  => ['any'], sub { 'OK' } );
    method 'test_execute'  => ( execute => sub { 'OK' } );
    #method 'test_string'   => ( execute => '_execute_test_string' );
    #method 'test_default';
    #method 'test_explicit';

    sub _execute_test_string  { 'OK' }   
    sub _execute_test_default { 'OK' }   

    #execute 'test_explicit' => sub { 'OK' };

    no MooseX::Params;
}

my $object = TestExecute->new;

foreach my $test (qw(test_only test_trailing test_execute))
{
    is($object->$test, 'OK', $test);
}

done_testing();
