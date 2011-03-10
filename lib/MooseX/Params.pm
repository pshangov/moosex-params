package MooseX::Params;

use strict;
use warnings;

use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::Params::Meta::Method;
use MooseX::Params::Meta::Parameter;
use Tie::IxHash;
use Data::Dumper::Concise;
use Perl6::Caller;
use Devel::Caller;
use Class::MOP::Class;
use Moose::Util::TypeConstraints qw(find_type_constraint);
use Package::Stash;
use Sub::Prototype qw(set_prototype);

Moose::Exporter->setup_import_methods(
	with_meta => [qw(method param params)],
	also      => 'Moose',
);

sub init_meta 
{
	shift; # ignore caller name
	my %args = @_;
	Moose->init_meta(%args);
	Moose::Util::MetaRole::apply_metaroles(
		for => $args{for_class},
		class_metaroles => { class => ['MooseX::Params::Meta::Class'] },
	);	
}

sub method
{
	my ( $meta, $name, @options ) = @_;
	
	my ($coderef, %options);

	if (!@options)
	{
		Carp::croak("Cannot create method without specifications");
	}
	elsif (@options == 1 and ref $options[0] eq 'CODE')
	{
		$coderef = shift @options;
	}
	elsif (@options % 2 and ref $options[-1] eq 'CODE')
	{
		$coderef = pop @options;
		%options = @options;
		
		if ($options{execute})
		{
			Carp::croak("Cannot create method: we found both an 'execute' option and a trailing coderef");
		}
	}
	elsif (!(@options % 2))
	{
		%options = @options;
		
		if ( exists $options{execute} )
		{
			my $reftype = ref $options{execute};
			if (!$reftype)
			{
				$coderef = $meta->get_method($options{execute});
				Carp::croak("Cannot create method: 'execute' points to a non-existant sub '$options{execute}'");
			}
			elsif ($reftype eq 'CODE')
			{
				$coderef = $options{execute};
			}
			else
			{
				Carp::croak("Option 'execute' must be a coderef, not $reftype");
			}
		}
		else
		{
			Carp::croak("Cannot create method without code to execute");
		}
	}
	else
	{
		Carp::croak("Cannot create method $name: invalid arguments");
	}

    my $wrapped_coderef = sub 
    {
        local our %_ = _process_parameters(@_);
        $coderef->(@_);
    };

    if ( my $prototype = delete $options{prototype} )
    {
        set_prototype($wrapped_coderef, $prototype);
    }

	my $method = MooseX::Params::Meta::Method->wrap(
		$wrapped_coderef,
		name         => $name,
		package_name => $meta->{package},
	);

	if (%options)
	{
		if ($options{params})
		{
			if (ref $options{params} eq 'ARRAY')
			{
				my @parameters = _inflate_parameters(@{$options{params}});
				$method->parameters(\@parameters);
			}
			#elsif ($options{params} eq 'HASH') { }
			else
			{
				Carp::croak("Argument to 'params' must be either an arrayref or a hashref");
			}
		}
	}
	$meta->add_method($name, $method);
}

sub param
{
	my ( $meta, $name, %options ) = @_;
	$meta->add_parameter($name);
}

sub params
{
	my $meta = shift;
	my @parameters = @_;

  	my $frame = 3;
	my ($package_name, $method_name) =  caller($frame)->subroutine  =~ /^(.+)::(\w+)$/;
    
    my $package_with_percent_underscore = 'MooseX::Params';

    my $stash = Package::Stash->new($package_with_percent_underscore);
    my %args = %{ $stash->get_symbol('%_') };

    # optionally dereference last requested parameter
    my $last_param = pop @parameters;
    my ($last_param_object) = $meta->get_method($method_name)->get_parameters_by_name($last_param);
    my @last_value = my $last_value = $args{$last_param};

    my $auto_deref;

    if ($last_param_object->auto_deref)
    {
        if ( ref $last_value eq 'HASH' )
        {
            @last_value = %$last_value;
            $auto_deref++;
        }
        elsif ( ref $last_value eq 'ARRAY' )
        {
            @last_value = @$last_value;
            $auto_deref++;
        }
    }

    my @all_values = ( @args{@parameters}, @last_value );

    if (@parameters == 0 and !$auto_deref)
    {
        return $last_value;
    }
    else
    {
        return @all_values;
    }
}

sub _process_parameters
{
    my @parameters = @_;

   	my $frame = 1;
	my ($package_name, $method_name) =  caller($frame)->subroutine  =~ /^(.+)::(\w+)$/;
	
    my $meta = Class::MOP::Class->initialize($package_name);
	my $method = $meta->get_method($method_name);

	my @parameter_objects = $method->get_parameters if $method->has_parameters;;
    
    my %return_values;

    foreach my $param (@parameter_objects)
    {
        my $value = $parameters[$param->index + $method->index_offset];
        if ( $param->required and not defined $value )
        {
            Carp::croak "Parameter " . $param->name . " is required";
        }

        if ( $param->constraint )
        {
            my $constraint = find_type_constraint($param->constraint)
                or Carp::croak("Could not find definition of type '" . $param->constraint . "'");

            if ($param->coerce and $constraint->has_coercion)
            {
                $value = $constraint->assert_coerce($value);
            }

            $constraint->assert_valid($value);
        }

        $return_values{$param->name} = $value;
    }
    return %return_values;
}

sub _inflate_parameters
{
	my @params = @_;
	my $position = 0;
	my @inflated_parameters;

	for ( my $i = 0; $i <= $#params; $i++ )
	{
		my $current = $params[$i];
		my $next = $i < $#params ? $params[$i+1] : undef;
		my $parameter;
		
		if (ref $next)
        # next value is a parameter specifiction
		{
			$parameter = MooseX::Params::Meta::Parameter->new(
				type  => 'positional',
				index => $position,
				name  => $current,
				%$next,
			);
			$i++;
		}
		else
		{
			$parameter = MooseX::Params::Meta::Parameter->new(
				type  => 'positional',
                index => $position,
                name  => $current
			);
		}
		
		push @inflated_parameters, $parameter;
		$position++;
	}

	return @inflated_parameters;
}



1;
