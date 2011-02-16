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

Moose::Exporter->setup_import_methods(
	with_meta => [qw(method param params)],
	#as_is     => [qw(params)],
	also      => 'Moose',
);

sub init_meta 
{
	shift;
	my %args = @_;
	Moose->init_meta(%args);
	Moose::Util::MetaRole::apply_metaroles(
		for => $args{for_class},
		class_metaroles => { class => ['MooseXParamMetaClass'] },
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
				Carp::croak("Execute must be a coderef");
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

	my $method = MooseXParamMetaMethod->wrap(
		$coderef,
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

	my $frame = 2;

	my $method_name = caller($frame)->subroutine;
	$method_name =~ s/^.+::(\w+)$/$1/;
	
	my $method = $meta->get_method($method_name);
	my @parameter_objects = $method->get_parameters_by_name(@parameters);
	my $offset = $method->index_offset;
	my @indexes = map { $_->index + $offset } @parameter_objects;

	return (Devel::Caller::caller_args($frame))[@indexes];
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
		{
			$parameter = MooseXParamMetaParameter->new(
				type  => 'positional',
				index => $position,
				name  => $current,
				%$next,
			);
			$i++;
		}
		else
		{
			$parameter = MooseXParamMetaParameter->new(
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
