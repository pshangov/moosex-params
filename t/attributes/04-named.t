use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use MooseX::Params::Interface::Attributes;

    sub name :Args(Str :first, Str :last) {
        "$_{first} $_{last}"
    }

    sub title :Args(Str name, Str :title) {
        $_{title} ? "$_{title} $_{name}" : $_{name}
    }
}

my $object = TestExecute->new;

is( $object->name( first => 'Abraham', last => 'Lincoln'), 'Abraham Lincoln', 'named parameters' );
is( $object->title('Abraham Lincoln', title => 'President'), 'President Abraham Lincoln', 'mixed parameters' );

done_testing();
