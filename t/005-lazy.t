use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use MooseX::Params;
    use Devel::Dwarn;
    use Scalar::Util qw(blessed);

    has 'question' =>
    (
        is      => 'ro',
        isa     => 'Str',
        default => 'Why?',
    );

    method 'test' =>
    (
        params => [ 'answer' => { isa => 'Int', lazy_build => 1 } ],
        sub { $_{answer} }
    );

    method 'selfish' =>
    (
        params => [ statement => { isa => 'Str', lazy_build => 1 } ],
        sub { $_{statement} }
    );

    method 'parametric' =>
    (
        params => [
            answer    => { isa => 'Int', lazy_build => 1 },
            statement => { isa => 'Str', lazy => 1, builder => '_build_my_statement' },
        ],
        sub { $_{statement} }
    );

    sub _build_param_answer    { 42 }
    sub _build_param_statement { "The question is '" . $self->question . "'" }
    sub _build_my_statement    { "The answer is '$_{answer}'" }

    no MooseX::Params;
}

my $object = TestExecute->new;
is( $object->test(41), 41, 'lazy with supplied value');
is( $object->test, 42, 'lazy without supplied value' );
is( $object->selfish, "The question is 'Why?'", 'lazy with $self' );
is( $object->parametric, "The answer is '42'", 'lazy with another parameter' );

done_testing();
