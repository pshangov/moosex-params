package MooseX::Params;

use strict;
use warnings;
use 5.10.0;
use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::Params::Meta::Method;
use MooseX::Params::Meta::Parameter;
use Tie::IxHash;
use Data::Dumper::Concise;
use Devel::Dwarn;
use Perl6::Caller;
use Devel::Caller;
use Class::MOP::Class;
use Moose::Util::TypeConstraints qw(find_type_constraint);
use Package::Stash;
use Sub::Prototype qw(set_prototype);
use B::Hooks::EndOfScope qw(on_scope_end);
use Hook::AfterRuntime qw(after_runtime);
use Scalar::Util qw(isweak weaken);
use Variable::Magic qw();
use List::Util qw(first max);
use Try::Tiny qw(try catch);
use MooseX::Params::Util::Parameter;
use MooseX::Params::Magic::Wizard;

my $wizard = MooseX::Params::Magic::Wizard->new;

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
	with_meta => [qw(method param params execute)],
	also      => 'Moose',
    install   => [qw(unimport)]
);

sub _finalize
{
    my $class = shift;
    my $metaclass = $class->meta;
    
    my @methods = grep { $_->can('_delayed') and $_->_delayed } $metaclass->get_all_methods;

    foreach my $method (@methods)
    {
        my $name = $method->name;
        my $package_name = $method->package_name;
        my $execute = $method->_execute;
 	    my $coderef = $metaclass->get_method($execute);
    	Carp::croak("Cannot create method: 'execute' points to a non-existant sub '$execute'") unless $coderef;
        my $wrapped_coderef = MooseX::Params::Util::Parameter::wrap($coderef, $package_name, $method->parameters);
        

        my $old_method = $metaclass->remove_method($name);

        my $new_method = MooseX::Params::Meta::Method->wrap(
            $wrapped_coderef,
        	name         => $name,
            package_name => $package_name,
        );

        $metaclass->add_method($name, $new_method);
    }
}

sub import {
    my $frame = 1;
    my ($package_name, $method_name) =  caller($frame)->subroutine  =~ /^(.+)::(\w+)$/;

    my $stash = Package::Stash->new($package_name);
    $stash->add_symbol('%_');
    $stash->add_symbol('$self', "George");

    after_runtime { _finalize($package_name) };
    goto &$import;
}

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

sub execute
{
    my ($meta, $name, $coderef) = @_;

    my $old_method = $meta->remove_method($name);
    my $package_name = $old_method->package_name;
    my $wrapped_coderef = MooseX::Params::Util::Parameter::wrap($coderef, $package_name, $old_method->parameters);

    my $new_method = MooseX::Params::Meta::Method->wrap(
        $wrapped_coderef,
        name         => $name,
        package_name => $package_name,
        _delayed     => 0,
    );

    $meta->add_method($name, $new_method);
}

sub method
{
	my ( $meta, $name, @options ) = @_;

	my $stash = Package::Stash->new($meta->{package});
	my ($coderef, %options);

	if (!@options)
	{
		$options{execute} = "_execute_$name";
		$coderef = $stash->get_symbol('&' . $options{execute});
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
				$coderef = $stash->get_symbol('&' . $options{execute});
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
            $options{execute} = "_execute_$name";
			$coderef = $stash->get_symbol('&' . $options{execute});
		}
	}
	else
	{
		Carp::croak("Cannot create method $name: invalid arguments");
	}

	my %parameters;
	if (%options)
	{
		if ($options{params})
		{
			if (ref $options{params} eq 'ARRAY')
			{
				%parameters = _inflate_parameters($meta->{package}, @{$options{params}});
			}
			#elsif ($options{params} eq 'HASH') { }
			else
			{
				Carp::croak("Argument to 'params' must be either an arrayref or a hashref");
			}
		}
	}

    my $prototype = delete $options{prototype};
    my $package_name = $meta->{package};
	# TODO execute later (after parameters are determined)
	my $wrapped_coderef = MooseX::Params::Util::Parameter::wrap($coderef, $package_name, \%parameters, $prototype);

	my $method = MooseX::Params::Meta::Method->wrap(
		$wrapped_coderef,
		name         => $name,
		package_name => $meta->{package},
		parameters   => \%parameters,
	);

    $meta->add_method($name, $method) unless defined wantarray;

    return $method;
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

sub _inflate_parameters
{
	my $package = shift;
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
				type    => 'positional',
				index   => $position,
				name    => $current,
				package => $package,
				%$next,
			);
			$i++;
		}
		else
		{
			$parameter = MooseX::Params::Meta::Parameter->new(
				type    => 'positional',
                index   => $position,
                name    => $current,
				package => $package,
			);
		}
		
		push @inflated_parameters, $parameter;
		$position++;
	}
	
	my %inflated_parameters = map { $_->name => $_ } @inflated_parameters;

	return %inflated_parameters;
}

1;
