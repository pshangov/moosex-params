package MooseX::Params::Meta::Parameter;

use Moose;

has 'name' =>
(
	is       => 'rw',
	isa      => 'Str',
	required => 1,
);

has 'type' =>
(
	is       => 'rw',
	isa      => 'Str',
	required => 1,
);

has 'index' =>
(
	is       => 'rw',
	isa      => 'Int',
	required => 1,
);

has 'constraint' =>
(
	is       => 'rw',
	isa      => 'Str',
    init_arg => 'isa',
);

has 'default' => 
(
    is => 'ro',
);

has 'does' =>
(
	is  => 'rw',
	isa => 'Str',
);

has 'coerce' =>
(
	is  => 'rw',
	isa => 'Bool',
);

has 'trigger' =>
(
	is  => 'rw',
	isa => 'CodeRef',
);

has 'required' =>
(
	is  => 'rw',
	isa => 'Bool',
);

has 'lazy' =>
(
	is  => 'rw',
	isa => 'Bool',
);

has 'weak_ref' =>
(
	is  => 'rw',
	isa => 'Bool',
);

has 'auto_deref' =>
(
	is  => 'rw',
	isa => 'Bool',
);

has 'lazy_build' =>
(
	is      => 'rw',
	isa     => 'Bool',
    trigger => sub 
    {
        my $self = shift;
        $self->lazy(1);
        $self->builder('_build_param_' . $self->name);
    }
);

has 'builder' =>
(
	is  => 'rw',
	isa => 'Str',
);

has 'documentation' =>
(
	is  => 'rw',
	isa => 'Str',
);

no Moose;

1;

