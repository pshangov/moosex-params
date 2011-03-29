use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use MooseX::Params;

    method 'name' => 
    (
        params => [ 
            'first' => { isa => 'Str', type => 'named' },
            'last'  => { isa => 'Str', type => 'named' },
        ],
        sub { "$_{first} $_{last}" }
    );

    method 'title' => 
    (
        params => [ 
            'name'  => { isa => 'Str' },
            'title' => { isa => 'Str', type => 'named' },
        ],
        sub { $_{title} ? "$_{title} $_{name}" : $_{name} }
    );

    no MooseX::Params;
}

my $object = TestExecute->new;

is( $object->name( first => 'Abraham', last => 'Lincoln'), 'Abraham Lincoln', 'named parameters' );
is( $object->title('Abraham Lincoln', title => 'President'), 'President Abraham Lincoln', 'mixed parameters' );

done_testing();
