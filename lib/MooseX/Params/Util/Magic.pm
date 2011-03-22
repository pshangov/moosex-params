package MooseX::Params::Util::Magic;

use 5.010;
use strict;
use warnings;
use List::Util ();
use Carp ();
use MooseX::Params::Util::Parameter;
use parent 'MooseX::Params::Util::Wizard';

sub data
{ 
    my ($ref, %data) = @_;
    return \%data;
}

sub fetch
{
    my ( $ref, $data, $key ) = @_; 
 	
	# throw exception if $key is not a valid parameter name
	Carp::croak("Attempt to access non-existany parameter $key") 
		unless $key ~~ @{$data->{allowed}};
	
	# quit if this parameter has already been processed
    return if exists $ref->{$key};
	
	#my $builder = $data->{stash}->get_symbol("&_build_param_$key");
	my $builder = $data->{parameters}{$key}->{builder_sub};
    my $wrapped = $data->{wrapper}->($builder, $data->{stash}, $key);

	# this check should not be necessary
    if ($builder)
    {
        my %updated = $wrapped->($data->{self}, %$ref);
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

	# my $value = MooseX::Params::Util::Parameter::build($param, $data->{stash});
    # $value = MooseX::Params::Util::Parameter::build($param, $value);
}

sub store
{
	Carp::croak "Don't touch me!" if caller ne __PACKAGE__;
}

1;
