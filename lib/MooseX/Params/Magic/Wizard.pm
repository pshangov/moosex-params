package MooseX::Params::Magic::Wizard;

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
	Carp::croak("Attempt to access non-existany parameter $key") 
		unless $key ~~ $data->allowed_parameters;
	
	# quit if this parameter has already been processed
    return if exists $ref->{$key};
	
	my $builder = $data->get_parameter($key)->builder_sub;
    my $wrapped = $data->wrap($builder, $data->{stash}, $key);

	# this check should not be necessary
    if ($builder)
    {
        my %updated = $wrapped->($data->self, %$ref);
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