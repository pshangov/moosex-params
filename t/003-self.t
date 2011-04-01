use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use MooseX::Params;

    has 'first', is => 'rw', default => 'George';

    method 'test' => sub { $self->first . " is first!" };

    method 'lexical' => sub { my $self = "Peter"; return "$self is first!" };

    no MooseX::Params;
}

my $object = TestExecute->new;
my $local = $object->test;
my $lexical = $object->lexical;

is($local,   'George is first!', 'localized self');
is($lexical, 'Peter is first!',  'lexical self');

done_testing();
