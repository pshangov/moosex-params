package MooseX::Params::Magic::Wizard;

# ABSTRACT: Magic behavior for %_

use 5.010;
use strict;
use warnings;
use Carp ();
use MooseX::Params::Util::Parameter;
use MooseX::Params::Magic::Data;
use parent 'MooseX::Params::Magic::Base';

sub data
{
    my ($ref, %data) = @_;
    return MooseX::Params::Magic::Data->new(%data);
}

sub fetch
{
    my ( $ref, $data, $key ) = @_;

    # throw exception if $key is not a valid parameter name
    my @allowed = $data->allowed_parameters;
    Carp::croak("Attempt to access non-existany parameter $key")
        unless $key ~~ @allowed;

    # quit if this parameter has already been processed
    return if exists $ref->{$key};

    my $builder = $data->get_parameter($key)->builder_sub;
    my $wrapped = $data->wrap($builder, $data->package, $data->parameters, $key);

    # this check should not be necessary
    if ($builder)
    {
        my %updated = $wrapped->(%$ref);
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
    Carp::croak "Don't touch me!" if caller ne __PACKAGE__;
}

1;
