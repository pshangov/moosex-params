package User;

use strict;
use warnings;

use Sugar;

method 'test', [qw(name)], sub { return "Peter is a $_{position}" };

sub _build_param_name 
{ 
    return 'peter';
}

sub _build_param_position
{
    my %positions = (
        peter  => 'translator',
        george => 'programmer',
    );

    return $positions{$_{name}};
}

1;
