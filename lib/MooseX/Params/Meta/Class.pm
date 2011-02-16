package MooseX::Params::Meta::Class;

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
