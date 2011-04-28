package MooseX::Params::Interface::Attributes;

use strict;
use warnings;
use 5.010;
use Attribute::Handlers;
use Devel::Dwarn;
use Package::Stash;
use MooseX::Params::Util::Parameter;
use MooseX::Params::Meta::Method;
use Moose::Meta::Class;

sub import 
{
    my $inheritor = caller;

    my $stash = Package::Stash->new($inheritor);
    $stash->add_symbol('$self', undef);

    {
        no strict 'refs';
        push @{"$inheritor\::ISA"}, __PACKAGE__;
        use strict 'refs';
    }
}

sub Args :ATTR(CODE,RAWDATA)
{
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my ($name) = $$symbol =~ /.+::(\w+)$/;

    my $stash = Package::Stash->new($package);

    my %parameters = MooseX::Params::Util::Parameter::inflate_parameters(
        $package,
        map { $_->{name} => $_ } 
        MooseX::Params::Util::Parameter::parse_params_attribute($data)
    );
    
    my $coderef = \&$symbol;
    my $wrapped_coderef = MooseX::Params::Util::Parameter::wrap($coderef, $package, \%parameters);

    my $method = MooseX::Params::Meta::Method->wrap(
        $wrapped_coderef,
        name         => $name,
        package_name => $package,
        parameters   => \%parameters,
    );

    my $meta = Moose::Meta::Class->initialize($package);
    $meta->add_method($name, $method);
}

1;
