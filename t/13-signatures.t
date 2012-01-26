use strict;
use warnings;

use Test::Most;

{
    package TestExecute;
    use MooseX::Params;

    sub new { bless {}, shift }
    
    sub add (self: a, b) { $_{a} + $_{b} }
    
    sub add3 (self: a, b, c) {
        $_{self}->add( $_{self}->add($_{a}, $_{b}), $_{c} ) 
    }

    sub fortytwo (self: Int first) :BuildArgs { $_{first} }

    sub thirty (self: Int first) :CheckArgs { $_{first} }

    sub _buildargs_fortytwo { shift, 42 }

    sub _checkargs_thirty { die unless $_{first} > 30 }
}

my $object = TestExecute->new;

#is $object->add(1,2), 3, "method with a signature";
#is $object->add3(1,2,3), 6, "method with a signature called within method";
is($object->fortytwo(24), 42, 'signature and buildargs');
#dies_ok { $object->test_fail(24) } 'signature and checkargs dies';
#lives_ok { $object->test_fail(42) } 'signature and checkargs lives';

done_testing;
