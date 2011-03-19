package Sugar;

use 5.010;
use lib 'C:\Development\MooseX-Params\lib';
use strict;
use warnings;
use Sub::Install;
use Perl6::Export::Attrs;
use Package::Stash;
use Variable::Magic;
use Magic;


sub method :Export(:DEFAULT)
{
    my ($name, $params, $coderef) = @_;
    my $package = caller();
    my $stash = Package::Stash->new($package);

    my $wrapped = wrap($coderef, $stash);

    Sub::Install::install_sub({
        code => $wrapped,
        into => $package,
        as   => $name
    });
}

sub wrap
{
    my ($coderef, $stash, $key) = @_;
    my $wizard = Magic->new;
    
    return sub 
    {
        local %_;
        Variable::Magic::cast(%_, $wizard,
            stash => $stash,
        );

        if ($key)
        {
            $_{$key} = $coderef->();
            return %_;
        }
        else
        {
            return $coderef->();
        }
    }
}

1;
