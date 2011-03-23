package MooseX::Params::Util::Parameter;

use strict;
use warnings;

use Moose::Util::TypeConstraints qw(find_type_constraint);
use Try::Tiny qw(try catch);

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
    my ($param, $stash, $default_only) = @_;

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
            return if $default_only;
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
        local *{$package_name.'::self'} = \$self;
        use strict 'refs';
        
		# localize and enchant %_
		local %_;
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
            $value = MooseX::Params::Util::validate($parameters->{$key}, $value);
			$_{$key} = $value;
            return %_;
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
