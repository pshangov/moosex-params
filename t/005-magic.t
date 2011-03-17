use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use MooseX::Params;

    method 'test' => 
    (
        params => [ 'first' => { isa => 'Int'} ],
        sub { $_{first} }
    ); 

    method 'another' => 
    (
        params => [ 'one' => { isa => 'Int'} ],
        sub { $_{one} }
    ); 

    no MooseX::Params;
}

my $object = TestExecute->new;
ok( $object->test(42) );
ok( $object->another(42) );

done_testing();
