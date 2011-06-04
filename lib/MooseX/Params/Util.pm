package MooseX::Params::Util;

# ABSTRACT: Parameter processing utilities

use strict;
use warnings;
use 5.10.0;
use Moose::Util::TypeConstraints qw(find_type_constraint);
use Try::Tiny                    qw(try catch);
use List::Util                   qw(max);
use Scalar::Util                 qw(isweak);
use Perl6::Caller                qw(caller);
use B::Hooks::EndOfScope         qw(on_scope_end); # magic fails without this, have to find out why ...
use Class::MOP::Class;
use Package::Stash;
use Text::CSV_XS;
use MooseX::Params::Meta::Parameter;
use MooseX::Params::Magic::Wizard;

# DESCRIPTION: Build a parameter from either a default value or a builder
# USED BY:     MooseX::Params::Util::process
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

# DESCRIPTION: Localize %_ around a method
# USED BY:     MooseX::Params::Args
sub wrap_method
{
    my ($coderef, $package, $parameters) = @_;

    return sub
    {
        local %_ = process(@_);

        my $wizard = MooseX::Params::Magic::Wizard->new;

        Variable::Magic::cast(%_, $wizard,
            parameters => $parameters,
            self       => $_{self},       # needed to pass as first argument to parameter builders
            wrapper    => \&wrap_param_builder,
            package    => $package,
        );

        return $coderef->(@_);
    };
}

# DESCRIPTION: Localize %_ around a parameter builder
# USED BY:     MooseX::Params::Wizard::fetch
sub wrap_param_builder
{
    my ($coderef, $package_name, $parameters, $key) = @_;

    return sub
    {
        local %_ = @_[1 .. $#_];

        my $wizard = MooseX::Params::Magic::Wizard->new;
        
        Variable::Magic::cast(%_, $wizard,
            parameters => $parameters,
            self       => \$_{self},       # needed to pass as first argument to parameter builders
            wrapper    => \&wrap_param_builder,
            package    => $package_name,
        );

        my $value = validate($parameters->{$key}, $coderef->($_{self}, %_));
        return %_, $key => $value;
    };
}

# DESCRIPTION: Get the parameters passed to a method, pair them with parameter definitions,
#              build, coerce, validate and return them as a hash
# USED BY:     MooseX::Params::Util::wrap_method
#              MooseX::Params::Util::wrap_param_builder
sub process
{
    my @parameters = @_;

    # get parameter definitions from meta class
    my $frame = 1;
    my ($package_name, $method_name) = caller($frame)->subroutine  =~ /^(.+)::(\w+)$/;
    my $meta = Class::MOP::Class->initialize($package_name);
    my $method = $meta->get_method($method_name);
    my @parameter_objects = $method->all_parameters if $method->has_parameters;
    return unless @parameter_objects;

    # separate named from positional parameters
    my $last_index = $#parameters;

    my $last_positional_index = max
        map  { $_->index }
        grep { $_->type eq 'positional' }
        @parameter_objects;

    $last_positional_index++;

    my %named = @parameters[ $last_positional_index .. $last_index ];

    # start processing 
    my %return_values;

    my $stash = Package::Stash->new($package_name);

    foreach my $param (@parameter_objects)
    {
        # $is_set - has a value been passed for this parameter
        # $is_required - is the parameter required
        # $is_lazy - should we build the value now or on first use
        # $has_default - does the parameter have a default value or a builder
        # $original_value - the value passed for this parameter
        # $value - the value to be returned for this parameter, after any coercions

        my ( $is_set, $original_value );

        if ( $param->type eq 'positional' )
        {
            $is_set = $param->index > $last_index ? 0 : 1;
            $original_value = $parameters[$param->index] if $is_set;
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
            Carp::croak ("Parameter " . $param->name . " is required") unless $has_default;
            $value = MooseX::Params::Util::build($param, $stash);
        }
        # if not required and not set, but not lazy either, check for a default
        elsif ( !$is_set and !$is_required and !$is_lazy and $has_default )
        {
            $value = MooseX::Params::Util::build($param, $stash);
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

        $value = MooseX::Params::Util::validate($param, $value);

        $return_values{$param->name} = $value;
        
        #FIXME
        if ($param->weak_ref and !isweak($value))
        {
            #weaken($value);
            #weaken($return_values{$param->name});
        }
    }

    return %return_values;
}

# DESCRIPTION: Given a parameter specification and a value, validate and coerce the value
# USED BY:     MooseX::Params::Util::process
sub validate
{
    my ($param, $value) = @_;

    if ( $param->constraint )
    {
        # fetch type definition
        my $constraint = find_type_constraint($param->constraint)
            or Carp::croak("Could not find definition of type '" . $param->constraint . "'");

        # coerce
        if ($param->coerce and $constraint->has_coercion)
        {
            $value = $constraint->assert_coerce($value);
        }

        # validate
        $constraint->assert_valid($value);
    }

    return $value;
}

sub parse_attribute
{
    my $string = shift;
    my @params;

    # join lines
    $string =~ s/\R//g;

    if ($string =~ s/^\s*(\w+)://)
    {
        my $invocant = $1;

        push @params, {
            name     => $invocant,
            init_arg => $invocant,
            required => 1,
            type     => 'positional',
            #TODO isa => ,
        };
    }

    my $csv_parser = Text::CSV_XS->new({ allow_loose_quotes => 1 });
    $csv_parser->parse($string) or Carp::croak("Cannot parse param specs");

    my $format = qr/^
        # TYPE AND COERCION
        ( (?<coerce>\&)? (?<type> [\w\:\[\]]+) \s+ )?

        # LAZY_BUILD
        (?<default>=)?

        # SLURPY
        (?<slurpy>\*)?

        # NAME
        (
             ( (?<named>:) (?<init_arg>\w*) \( (?<name>\w+) \) )
            |( (?<named>:)?                    (?<init_arg>(?<name>\w+)) )
        )

        # REQUIRED OR OPTIONAL
        (?<required>[!?])? \s*

        # DEFAULT VALUE
        (
            (?<default>=)\s*(
                  (?<number> \d+ )
                | ( (?<code>\w+) (\(\))? )
                | ( (?<delimiter>["']) (?<string>.*) \g{delimiter} )
             )?
        )?

    $/x;


    foreach my $param ($csv_parser->fields)
    {
        $param =~ s/^\s*//;
        $param =~ s/\s*$//;

        if ($param =~ $format)
        {
            my %options =
            (
                name     => $+{name},
                init_arg => $+{init_arg} eq '' ? undef : $+{init_arg},
                required => ( defined $+{required} and $+{required} eq '?' ) ? 0 : 1,
                type     => $+{named} ? 'named' : 'positional',
                slurpy   => $+{slurpy} ? 1 : 0,
                isa      => defined $+{type} ? $+{type} : undef,
                coerce   => $+{coerce} ? 1 : 0,
                default  => defined $+{number} ? $+{number} : $+{string},
                builder  => ( defined $+{default} and not defined $+{number} and not defined $+{string} )
                                ? ( defined $+{code} ? $+{code} : "_build_param_$+{name}" ) : undef,
                lazy     => ( defined $+{default} and not defined $+{number} and not defined $+{string} ) ? 1 : 0,
            );

            push @params, \%options;
        }
        else
        {
            Carp::croak "Error parsing parameter specification '$param'";
        }
    }

    return @params;
}

# TODO:        Merge with process_attribute
# DESCRIPTION: Given a parameter specification attribute as a string,
#              inflate into a list of MooseX::Param::Meta::Parameter objects
# USED BY:     MooseX::Params::Args
sub inflate_parameters
{
    my ($package, $data) = @_;

    my @parameters = parse_attribute($data);
    my $position = 0;
    my @inflated_parameters;

    foreach my $param (@parameters)
    {
        my $parameter_object = MooseX::Params::Meta::Parameter->new(
            index   => $position,
            package => $package,
            %$param,
        );

        push @inflated_parameters, $parameter_object;
        $position++;
    }

    my %inflated_parameters = map { $_->name => $_ } @inflated_parameters;

    return \%inflated_parameters;
}

1;