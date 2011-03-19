use strict;
use warnings;

use Variable::Magic qw(wizard cast);

sub _build_param { ... }

sub generate_method 
{
    return sub 
    {
        local %_ = %$params;
        cast %_;
        $coderef->(%_);
    }
}

sub fetch 
{
    my ($ref, $data, $key);

    my $build_sub = $data->{build_sub};

    if ($lazy_and_empty)
    {
        %updated = $build_sub->($coderef);
        $ref = \%updated;
    }
}
