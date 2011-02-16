use strict;
use warnings;

use TestParams;
use Data::Dumper::Concise;

my $object = TestParam->new;

$object->try_me;

$object->basic_options(qw(1 2 3));

$object->try_execute;
