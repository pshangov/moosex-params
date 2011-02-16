package MooseX::Params::Meta::Parameter;

use Moose;

has 'name' =>
(
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'type' =>
(
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'index' =>
(
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

1;

