use 5.010;

package MooseX::Params::Meta::Method;

use Moose;
use List::Util qw(max);

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
	},
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

sub _validate_parameters
{
	my ($self, %parameters) = @_;
}

sub _convert_argv_to_hash
{
	my ($self, @argv) = @_;

	my (%parameters, %argv);
	
	my @positional = grep { $_->type eq 'positional' } $self->get_parameters;
	my @named      = grep { $_->type eq 'named'      } $self->get_parameters;

	my $last_positional_index = max map { $_->index } @positional;
	my $first_named_index = $last_positional_index + 1;
	my $last_argv_index = $#argv;

	if ( $last_positional_index >= $last_argv_index )
	{
		@positional = grep { $_->index <= $last_argv_index } @positional;
		
	}
	else
	{
		my @extra = @argv[$first_named_index .. $last_argv_index];

		if (@named)
		{
			%argv = @extra;

			foreach my $name ( map { $_->name } @named )
			{
				$parameters{$name} = delete $argv{$name} if exists $argv{$name};
			}
			$parameters{'__!extra'} = \(%argv);
		}
		else
		{
			$parameters{'__!extra'} = \@extra;
		}
	}

	$parameters{$_->name} = $argv[$_->index] for @positional;

	return %parameters;
}

1;
