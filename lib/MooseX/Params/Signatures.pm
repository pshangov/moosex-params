package MooseX::Params::Signatures;

use Moose::Exporter;
use MooseX::Params::TypeConstraints;
use Sub::Mutate qw(when_sub_bodied sub_prototype mutate_sub_prototype);
use Moose::Meta::Class;
use MooseX::Params::Util;
use Carp qw(croak);

sub import {
    require warnings::illegalproto;
    warnings::illegalproto->unimport;

    no strict 'refs';
    *{ caller . "::method"}   = \&method;
    *{ caller . "::function"} = \&function;
    *{ caller . "::annotate"} = \&annotate;
    *{ caller . "::validate"} = \&validate;
}

sub init_meta {
    shift;
    Moose->init_meta(@_);
}

sub function {
    push @_, 1;
    goto &method;
}

sub method {
    my ($name, $coderef, $is_function) = @_;

    croak "MooseX::Params currently does not support anonymous subroutines"
        if ref $name eq 'CODE';

    my $package = caller;
    my $meta    = Moose::Meta::Class->initialize($package);

    my $proto = sub_prototype($coderef);
    mutate_sub_prototype($coderef, undef); 

    my $method = MooseX::Params::Meta::Method->wrap(
        MooseX::Params::Util::wrap_method($package, $name, $coderef),
        name => $name,
        package_name => $package,
        associate_metaclass => $meta,
    );

    $meta->add_method($name, $method);

    my @parameters = $is_function
        ? MooseX::Params::Util::parse_function_proto($proto)
        : MooseX::Params::Util::parse_method_proto($proto);

    my $position = 0;
    my %inflated_parameters;

    foreach my $param (@parameters)
    {
        my $parameter_object = MooseX::Params::Meta::Parameter->new(
            index   => $position,
            package => $package,
            %$param,
        );

        $inflated_parameters{$parameter_object->name} = $parameter_object;
        $position++;
    }

    $method->parameters(\%inflated_parameters);
}

sub validate {
    my ($name, %options) = @_;

    my $package = caller;
    my $meta    = Moose::Meta::Class->initialize($package);
    my $method  = $meta->get_method($name);

    foreach my $param_name (keys %options) {
        my $parameter = $method->get_parameter($param_name);
        next unless $parameter;
        
        while (my ($key, $value) = each %{ $options{$param_name}}) {
            $key = 'constraint' if $key eq 'isa';
            $parameter->$key($value);
            $parameter->lazy(1) if $key =~ /^(builder)$/, # FIXME
        }

    }
}

sub annotate {
    my ($name, %options) = @_;

    my $package = caller;
    my $meta    = Moose::Meta::Class->initialize($package);
    my $method  = $meta->get_method($name);

    while (my ($key, $value) = each %options) {
        $method->$key($value);
    }
}

1;
