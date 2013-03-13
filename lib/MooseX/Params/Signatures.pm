package MooseX::Params::Signatures;

use Moose::Exporter;
use Sub::Mutate qw(when_sub_bodied sub_prototype mutate_sub_prototype);
use Moose::Meta::Class;
use MooseX::Params::Util;

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
    with_meta => [qw(method annotate validate)],
    install   => [qw(unimport)]
);

sub import {
    require warnings::illegalproto;
    warnings::illegalproto->unimport;

    no strict 'refs';
    *{ caller . "::method"}   = \&method;
    *{ caller . "::annotate"} = \&annotate;
    *{ caller . "::validate"} = \&validate;
}

sub init_meta {
    shift;
    Moose->init_meta(@_);
}

sub method {
    my ($name, $coderef) = @_;

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

    my @parameters = MooseX::Params::Util::parse_prototype($proto);
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
    my ($meta, $name, %options) = @_;

    my $method = $meta->get_method($name);

    foreach my $param_name (keys %options) {
        my $parameter = $method->get_parameter($param_name);
        next unless $parameter;
        
        while (my ($key, $value) = each %{ $options{$param_name}}) {
            $parameter->$key($value);
        }

    }
}

sub annotate {
    my ($meta, $name, %options) = @_;

    my $method = $meta->get_method($name);

    while (my ($key, $value) = each %options) {
        $method->$key($value);
    }
}

1;
