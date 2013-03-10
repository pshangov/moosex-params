package MooseX::Params::Signatures;

use Moose::Exporter;
use Sub::Mutate qw(when_sub_bodied sub_prototype mutate_sub_prototype);
use MooseX::Params::Util qw(parse_prototype wrap_method);

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
    with_meta => [qw(method annotate validate)],
    install   => [qw(unimport)]
);

sub import {
    require warnings::illegalproto;
    warnings::illegalproto->unimport;

    goto &$import;
}

sub init_meta {
    shift;
    Moose->init_meta(@_);
}

sub method {
    my ($meta, $name, $coderef) = @_;

    my $proto = sub_prototype($name);
    my @parameters = parse_prototype($proto);
    mutate_sub_prototype($coderef, undef);

    my $wrapped = wrap_method(caller, $name, $coderef);
    my $method = $meta->add_method($name, $wrapped);

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
