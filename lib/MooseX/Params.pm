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

my $wizard = Variable::Magic::wizard (
    data  => sub 
    { 
        my ($ref, %data) = @_;
        return \%data;
    },
    fetch => sub 
    {
        my ( $ref, $data, $key ) = @_; 
        
        my @keys = @{ $data->{keys} };
        my @processed = @{ $data->{processed} };

        return unless ($key ~~ @keys);
        return if ($key ~~ @processed);

        my $param = first { $_->name eq $key } @{ $data->{parameters} };
        return unless $param and $param->lazy;

        my $value = MooseX::Params::Util::Parameter::build($param, $data->{stash});
        $value = MooseX::Params::Util::Parameter::build($param, $value);

        $ref->{$key} = $value;
        push @processed, $key;
        $data->{processed} = \@processed;
    },
    store => sub 
    { 
        my ( $ref, $data, $key ) = @_; 
        $data->{processed} = \( @{ $data->{processed} }, $key );
    },
);

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
        my $wrapped_coderef = _wrap_method($package_name, $coderef, $method->parameters);
        

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
    my $wrapped_coderef = _wrap_method($package_name, $coderef, $old_method->parameters);

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

	my ($coderef, %options);

	if (!@options)
	{
        $options{execute} = "_execute_$name";
        $options{_delayed} = 1;
        #Carp::croak("Cannot create method without specifications");
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
                $options{_delayed} = 1;
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
            $options{_delayed} = 1;
            #Carp::croak("Cannot create method without code to execute");
		}
	}
	else
	{
		Carp::croak("Cannot create method $name: invalid arguments");
	}

    my $prototype = delete $options{prototype};
    my $package_name = $meta->{package};
    my $wrapped_coderef = _wrap_method($package_name, $coderef, undef, $prototype);

    my $method;

    if ($options{_delayed})
    {
	    $method = MooseX::Params::Meta::Method->wrap(
		    sub {},
            _execute     => $options{execute},
            _delayed     => 1,
    		name         => $name,
	    	package_name => $meta->{package},
	    );
    }
    else
    {
    	$method = MooseX::Params::Meta::Method->wrap(
		    $wrapped_coderef,
    		name         => $name,
	    	package_name => $meta->{package},
	    );
    }

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
    
    $meta->add_method($name, $method) unless defined wantarray;

    return $method;
}

sub _wrap_method
{
    my ($package_name, $coderef, $parameters, $prototype) = @_;

    my $stash = Package::Stash->new($package_name);

    my $wrapped_coderef = sub 
    {
        no strict 'refs';
        local %_ = _process_parameters($stash, @_);
        Variable::Magic::cast(%_, $wizard, 
            stash        => $stash,
            parameters   => $parameters,
            keys         => [ map {$_->name} @$parameters ],
            processed    => [ keys %_ ],
            self         => \$_[0],
        );
        local *{$package_name.'::self'} = \$_[0];
        use strict 'refs';
        $coderef->(@_);
    };

    set_prototype($wrapped_coderef, $prototype) if $prototype;
    
    return $wrapped_coderef;
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
    my $stash = shift;
    my @parameters = @_;
    my $last_index = $#parameters;

   	my $frame = 1;
	my ($package_name, $method_name) =  caller($frame)->subroutine  =~ /^(.+)::(\w+)$/;
	
    my $meta = Class::MOP::Class->initialize($package_name);
	my $method = $meta->get_method($method_name);

	my @parameter_objects = $method->get_parameters if $method->has_parameters;

    return unless @parameter_objects;

    my $offset = $method->index_offset;

    my $last_positional_index = max 
        map  { $_->index + $offset } 
        grep { $_->type eq 'positional' } 
        @parameter_objects;
       
    $last_positional_index++;

    my %named = @parameters[ $last_positional_index .. $last_index ];

    my %return_values;

    foreach my $param (@parameter_objects)
    {   
        my ( $is_set, $original_value );

        if ( $param->type eq 'positional' )
        {
            my $index = $param->index + $offset;
            $is_set = $index > $last_index ? 0 : 1;
            $original_value = $parameters[$index] if $is_set;
        }
        else
        {
            $is_set = exists $named{$param->name};
            $original_value = $named{$param->name} if $is_set;
        }
        
        my $is_required = $param->required;
        my $has_default = defined $param->default;

        my $value;
        
        if ( !$is_set and $is_required )
        {
            MooseX::Params::Util::Parameter::check_required($param);
            $value = MooseX::Params::Util::Parameter::build($param, $stash);
        }
        elsif ( !$is_set and !$is_required and $has_default )
        {
            $value = MooseX::Params::Util::Parameter::build($param, $stash, 1); 
        }
        else
        {
            $value = $original_value;
        }

        $value = MooseX::Params::Util::Parameter::validate($param, $value);

        $return_values{$param->name} = $value;

        if ($param->weak_ref and !isweak($value))
        {
            #weaken($value);
            #weaken($return_values{$param->name});
        }
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
