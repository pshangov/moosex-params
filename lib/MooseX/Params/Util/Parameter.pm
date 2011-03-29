package MooseX::Params::Util::Parameter;

use strict;
use warnings;
use 5.10.0;
use Moose::Util::TypeConstraints qw(find_type_constraint);
use Try::Tiny qw(try catch);
use List::Util qw(max);
use Scalar::Util qw(isweak);
use Class::MOP::Class;
use Package::Stash;
use Perl6::Caller;
use B::Hooks::EndOfScope qw(on_scope_end); # magic fails without this, have to find out why ...

sub check_required
{
    my $param = shift;
    
    my $has_default = defined ($param->default) or $param->builder;
    my $is_required = $param->required;

    if ($is_required and !$has_default)
    {
        Carp::croak "Parameter " . $param->name . " is required";
    }
}

sub build
{
    my ($param, $stash) = @_;

    my $value;

    my $default = $param->default;

    if (defined $default and ref($default) ne 'CODE')
    {
        $value = $default;
    } 
    else 
    {
        my $coderef;

        if ($default)
        {
            $coderef = $default;
        }
        else
        {
            my $coderef = $stash->get_symbol('&' . $param->builder);
            Carp::croak("Cannot find builder " . $param->builder) unless $coderef;        
        }

        $value = try {
            $coderef->();
        } catch {
            Carp::croak("Error executing builder for parameter " . $param->name . ": $_");        
        };
    }

    return $value;
}

sub wrap
{
    my ($coderef, $package_name, $parameters, $key, $prototype) = @_;

    my $wizard = MooseX::Params::Magic::Wizard->new;
    
    my $wrapped = sub 
    {
		# localize $self
        my $self = $_[0];
		no strict 'refs';
        local *{$package_name.'::self'} = $key ? $self : \$self;
        use strict 'refs';
        
		# localize and enchant %_
		local %_ = $key ? @_[1 .. $#_] : process(@_);
        Variable::Magic::cast(%_, $wizard,
			parameters => $parameters,
            self       => \$self,       # needed to pass as first argument to parameter builders
			wrapper    => \&wrap,
			package    => $package_name,
        );

		# execute for a parameter builder
        if ($key)
		{
			my $value = $coderef->($self, %_);
            $value = MooseX::Params::Util::Parameter::validate($parameters->{$key}, $value);
            return %_, $key => $value;
        }
		# execute for a method
        else
        {
            return $coderef->(@_);
        }
    };

    set_prototype($wrapped, $prototype) if $prototype;

	return $wrapped;
}

sub process
{
    my @parameters = @_;
    my $last_index = $#parameters;

   	my $frame = 1;
	my ($package_name, $method_name) = caller($frame)->subroutine  =~ /^(.+)::(\w+)$/;
    my $stash = Package::Stash->new($package_name);

    my $meta = Class::MOP::Class->initialize($package_name);
	my $method = $meta->get_method($method_name);

	my @parameter_objects = $method->all_parameters if $method->has_parameters;

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
		my $is_lazy = $param->lazy;
        my $has_default = ( defined $param->default or $param->builder );

        my $value;
       
		# if required but not set, attempt to build the value
        if ( !$is_set and !$is_lazy and $is_required )
        {
            MooseX::Params::Util::Parameter::check_required($param);
            $value = MooseX::Params::Util::Parameter::build($param, $stash);
        }
		# if not required and not set, but not lazy either, check for a default
		elsif ( !$is_set and !$is_required and !$is_lazy and $has_default )
		{
		    $value = MooseX::Params::Util::Parameter::build($param, $stash); 
		}
		# lazy parameters are built later
		elsif ( !$is_set and $is_lazy)
		{
			next;
		}
        elsif ( $is_set )
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


sub validate
{
    my ($param, $value) = @_;

    if ( $param->constraint )
    {
        my $constraint = find_type_constraint($param->constraint)
            or Carp::croak("Could not find definition of type '" . $param->constraint . "'");
        
        # coerce
        if ($param->coerce and $constraint->has_coercion)
        {
            $value = $constraint->assert_coerce($value);
        }

        $constraint->assert_valid($value);
    }

    return $value;
}


1;
