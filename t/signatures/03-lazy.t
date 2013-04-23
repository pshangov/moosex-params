use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use MooseX::Params::Signatures;

    has 'question' => (
        is      => 'ro',
        isa     => 'Str',
        default => 'Why?',
    );

    method test => sub (answer) {
        $_{answer}
    };

    validate test => (
        answer => { isa => 'Int', lazy_build => 1 }
    );

    method selfish => sub (self: statement) {
        $_{statement}
    };

    validate selfish => (
        statement => { isa => 'Str', lazy_build => 1 }
    );

    method parametric => sub (answer, statement) {
        $_{statement}
    };

    validate parametric => (
        answer    => { isa => 'Int', lazy_build => 1 },
        statement => { isa => 'Str', builder => '_build_my_statement' },
    );

    sub _build_param_answer {
        42
    }

    sub _build_param_statement {
        "The question is '" . $_{self}->question . "'"
    }

    sub _build_my_statement {
        "The answer is '$_{answer}'"
    }
}

my $object = TestExecute->new;
is( $object->test(41), 41, 'lazy with supplied value');
is( $object->test, 42, 'lazy without supplied value' );
is( $object->selfish, "The question is 'Why?'", 'lazy with $self' );
is( $object->parametric, "The answer is '42'", 'lazy with another parameter' );

done_testing();

