use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use MooseX::Params;

    method 'test' => 
    (
        params => [ 
            'first' => 
            { 
                isa        => 'Int',
                lazy_build => 1,
            } 
        ],
        sub { $_{first} }
    ); 

    sub _build_param_first { 42 }

    no MooseX::Params;
}

my $object = TestExecute->new;
is( $object->test(42), 42 );

done_testing();
