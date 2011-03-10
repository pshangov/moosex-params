use strict;
use warnings;

use rlib;
use TestParams;
use Data::Dumper::Concise;

my $object = TestParams->new;

$object->try_me;

$object->basic_options(qw(1 2 3));

$object->try_execute;

$object->link('first_file.txt', 'second_file.txt');

$object->mysay(["Some saying", "Some other saying ..."]);

$object->mysay(["Booyah!", "Kaboom!"]);


