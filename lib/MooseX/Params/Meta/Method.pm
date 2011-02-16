use 5.010;

package MooseX::Params::Meta::Method;

use Moose;

extends 'Moose::Meta::Method';

has 'parameters' =>
(
	is        => 'rw',
	isa       => 'ArrayRef',
	traits    => ['Array'],
	predicate => 'has_parameters',
	handles   =>
	{
		get_parameters => 'elements',
		add_parameter  => 'push',
	}
);

has 'index_offset' =>
(
	is      => 'ro',
	isa     => 'Int',
	default => 1,
);

sub get_parameters_by_name
{
	my ($self, @names) = @_;

	return grep { $_->name ~~ @names } $self->get_parameters if $self->has_parameters;
}

1;
