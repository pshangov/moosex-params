package MooseX::Params::Meta::Class;

# ABSTRACT: The class metarole

use Moose::Role;

has 'parameters' =>
(
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    handles => { 'add_parameter' => 'push' },
);

no Moose::Role;

1;
