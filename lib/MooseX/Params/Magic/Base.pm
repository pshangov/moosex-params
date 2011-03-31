package MooseX::Params::Magic::Base;

# ABSTRACT: Base class for building Variable::Magic wizards

use strict;
use warnings;

use Variable::Magic ();
use Package::Stash  ();

sub new 
{
    my $stash = Package::Stash->new(shift);

    my @fields = qw(
        data
        get
        set
        len
        clear
        free
        copy
        local
        fetch
        store
        exists
        delete
        copy_key
        op_info  
    );

    my %map;

    foreach my $field (@fields)
    {
        my $coderef = $stash->get_symbol("&$field");
        $map{$field} = $coderef if $coderef;
    }

    return Variable::Magic::wizard(%map);
}

1;
