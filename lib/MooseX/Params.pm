package MooseX::Params;

# ABSTRACT: Subroutine signature declaration via attributes

use strict;
use warnings;
use 5.010;
use Attribute::Handlers;
use MooseX::Params::Util;
use MooseX::Params::Meta::Method;
use Moose::Meta::Class;
use Data::Printer;

sub import
{
    no strict 'refs';
    push @{caller.'::ISA'}, __PACKAGE__;
    use strict 'refs';
}

sub Args :ATTR(CODE,RAWDATA)
{
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my ($name)  = $$symbol =~ /.+::(\w+)$/;
    my $coderef = \&$symbol;

    my $parameters = MooseX::Params::Util::inflate_parameters($package, $data);

    my $wrapped_coderef = MooseX::Params::Util::wrap_method($coderef, $package, $parameters);

    my $method = MooseX::Params::Meta::Method->wrap(
        $wrapped_coderef,
        name         => $name,
        package_name => $package,
        parameters   => $parameters,
    );

    Moose::Meta::Class->initialize($package)->add_method($name, $method);
}

sub BuildArgs :ATTR(CODE,RAWDATA) 
{
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my ($name)  = $$symbol =~ /.+::(\w+)$/;    
    $data = "_buildargs_$name" unless $data;

    my $method = Moose::Meta::Class->initialize($package)->get_method($name);
    $method->buildargs($data);
}

sub CheckArgs :ATTR(CODE,RAWDATA) 
{
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my ($name)  = $$symbol =~ /.+::(\w+)$/;    
    $data = "_checkargs_$name" unless $data;

    my $method = Moose::Meta::Class->initialize($package)->get_method($name);
    $method->checkargs($data);
} 

1;
