package Magic;

use 5.010;
use strict;
use warnings;
use parent 'MooseX::Params::Util::Wizard';
use Data::Dumper::Concise;

sub data
{ 
    my ($ref, %data) = @_;
    return \%data;
}

sub fetch
{
    my ( $ref, $data, $key ) = @_; 

    return if exists $ref->{$key};

    my $builder = $data->{stash}->get_symbol("&_build_param_$key");

    my $wrapped = wrap_builder($builder, $data->{stash}, $key);

    if ($builder)
    {
        my %updated = $wrapped->();
        foreach my $updated_key ( keys %updated )
        {
            $ref->{$updated_key} = $updated{$updated_key} 
                unless exists $ref->{$updated_key};
        }
    }
    else
    {
        $ref->{$key} = undef;
    }
}

sub store
{
    die "Don't touch me!" if caller ne __PACKAGE__;
}

sub wrap_builder
{
    my ($coderef, $stash, $key) = @_;
    my $wizard = Magic->new;
    
    return sub 
    {
        local %_;
        Variable::Magic::cast(%_, $wizard,
            stash => $stash,
        );
        if ($key)
        {
            $_{$key} = $coderef->();
            return %_;
        }
        else
        {
            return $coderef->();
        }
    }
}

1;
