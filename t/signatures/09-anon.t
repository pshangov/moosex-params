use strict;
use warnings;

use Test::Most;
use MooseX::Params::Signatures;

eval 'my $sub = function sub (one) { 1 }';

like $@, qr/MooseX::Params currently does not support anonymous subroutines/,
    'anonymous subroutines not supported';

done_testing;
