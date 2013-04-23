use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use MooseX::Params::Signatures;

    method name => sub (:first, :last) {
        "$_{first} $_{last}"
    };

    validate name => (
        first => { isa => 'Str' },
        last  => { isa => 'Str' },
    );

    method title => sub (name, :title) {
        $_{title} ? "$_{title} $_{name}" : $_{name}
    };

    validate title => (
        name  => { isa => 'Str' },
        title => { isa => 'Str' },
    );

    method nick => sub (:name, :nick) {
        "$_{name} is $_{nick}"
    };

    validate nick => (
        name => { isa => 'Str' },
        nick => { isa => 'Str', init_arg => 'nickname' },
    );

    method initials => sub (:first, :last, :initials) {
        $_{initials}
    };

    validate initials => (
        first    => { isa => 'Str' },
        last     => { isa => 'Str' },
        initials => { isa => 'Str', lazy_build => 1 },
    );

    sub _build_param_initials
    {
        substr( $_{first}, 0, 1 ) . substr( $_{last}, 0, 1 )
    }
}

my $object = TestExecute->new;

is( $object->name( first => 'Abraham', last => 'Lincoln'), 'Abraham Lincoln', 'named parameters' );
is( $object->title('Abraham Lincoln', title => 'President'), 'President Abraham Lincoln', 'mixed parameters' );
is( $object->nick( name => 'Abraham', nickname => 'Abe'), 'Abraham is Abe', 'init_arg' );
is( $object->initials( first => 'Abraham', last => 'Lincoln'), 'AL', 'lazy' );

done_testing();
