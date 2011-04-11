package MooseX::Params::Interface::Attributes;

use strict;
use warnings;
use 5.010;
use Attribute::Handlers;
use Devel::Dwarn;
use Package::Stash;
use MooseX::Params::Util::Parameter;

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

sub Params :ATTR(CODE,RAWDATA)
{
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my ($name) = $$symbol =~ /.+::(\w+)$/;

    #my $wrapped = 

    my $stash = Package::Stash->new($package);
    $stash->add_symbol("&$name", sub { "hello!" });

    my @specs = MooseX::Params::Util::Parameter::parse_params_attribute($data);

    Dwarn \@specs;


}

1;
