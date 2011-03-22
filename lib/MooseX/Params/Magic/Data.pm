package MooseX::Params::Magic::Data;

use 5.010;
use Moose;

has 'parameters' =>
(
	is       => 'ro',
	isa      => 'HashRef[MooseX::Params::Meta::Parameter]',
	required => 1,
	traits   => [qw(Hash)],
	handles  => { 
		get_parameter      => 'get', 
		all_parameters     => 'elements',
		allowed_parameters => 'keys',

	},
);

has 'lazy' =>
(
	is       => 'ro',
	isa      => 'ArrayRef[Str]',
	required => 1,
	lazy     => 1,
	builder  => '_build_lazy',
	traits   => [qw(Array)],
	handles  => { lazy_parameters => 'elements' }
);

has 'self' =>
(
	is => 'ro',
);

has 'wrapper' =>
(
	is       => 'ro',
	isa      => 'CodeRef',
	required => 1,
	traits   => [qw(Code)],
	handles  => { wrap => 'execute' },
);

has 'package' =>
(
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

sub _build_lazy
{
	my $self = shift;
	my @lazy = map { $_->name } grep { $_->lazy } $self->all_parameters;
	return \@lazy;
}

1;
