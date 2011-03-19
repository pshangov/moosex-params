package MooseX::Params::Util::Magic;

use 5.010;
use strict;
use warnings;
use MooseX::Params::Util::Parameter;
use List::Util qw(first);
use parent 'MooseX::Params::Util::Wizard';

sub data
{ 
    my ($ref, %data) = @_;
    return \%data;
}

sub fetch
{
    my ( $ref, $data, $key ) = @_; 
    
    my @keys = @{ $data->{keys} };
    my @processed = @{ $data->{processed} };

    return unless ($key ~~ @keys);
    return if ($key ~~ @processed);

    my $param = first { $_->name eq $key } @{ $data->{parameters} };
    return unless $param and $param->lazy;

    my $value = MooseX::Params::Util::Parameter::build($param, $data->{stash});
    $value = MooseX::Params::Util::Parameter::build($param, $value);

    $ref->{$key} = $value;
    push @processed, $key;
    $data->{processed} = \@processed;
}

sub store
{
    my ( $ref, $data, $key ) = @_; 
    $data->{processed} = \( @{ $data->{processed} }, $key );
}

1;
