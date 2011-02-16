use strict;
use warnings;

use MooseX::Params qw(params);

### no args, assume positional

sub test_something
{
	my ( $one, $two ) = params;
}

test_something('first_value', 'second_value');

### arg names, assume named

sub test_something
{
	my ( $one, $two ) = params qw(first second);
}

test_something( first => 'first_value', second => 'second_value' );
test_something({ first => 'first_value', second => 'second_value' });

### args and options

sub test_something
{
	my ($one, $two, $opt) = params;
}

test_something( 'arg1', 'arg2', { first => 'first_value', second => 'second_value' });


use MooseX::Params;

method 'test_something' => sub { ... }

method 'test_something' => (
	params => [qw(one two opt)],
	execute => sub { ... },
);

method 'get_size' =>
(
	qw(:private :static :memoized),
	args =>
	[
		filenames => 
		{
			qw(:required :coerce :auto_deref)
			isa => 'ArrayRef[File]',
		},
		directory => 
		{ 
			qw(:required :named)
			isa => 'Dir', 
			default => '.' 
		},
		recurse => 
		{ 
			qw(:required :named),
			isa => 'Bool'
		},
	],
	returns => 'Array[Num]',
	execute => sub
	{
		my $self = shift;
		
		my ($filenames, $directory, $recurse) = args;

		my @filenames = args('filenames');

		#my ($self, $opt, @args) = args;
	
		# or

		my $self = shift;

		my @filenames = params('filenames');
		
		my $opt = params->options;
	}
);

### samples from core

function 'print' =>
(
	params    => 'Array[Str]',
	returns   => 'Bool';
	prototype => '@',
	execute   => sub
	{
		foreach my $string (params)
		{
			CORE::print $string;
		}
	},
);


function 'lc' =>
(
	params  => 'Str',
	returns => 'Str',
	execute => sub 
	{
		return CORE::lc params;
	},
);

function 'link' =>
(
	params =>
	[
		oldfile => { required => 1, isa => 'File', coerce => 1},
		newfile => { required => 1, isa => 'Str' },
	],
	returns => 'Bool',
	execute => sub
	{
		params('oldfile')->create_link(params('newfile'));
	}
);

function 'link' =>
(
	params =>
	[
		-oldfile => { required => 1, isa => 'File', coerce => 1},
		-newfile => { required => 1, isa => 'Str' },
	],
	returns => 'Bool',
	execute => sub
	{
		params(-oldfile)->create_link(params(-newfile));
	}
);

function 'open' =>
(
	params =>
	[
		filename => 
		{ 
			required => 1, 
			isa      => 'Str' 
		},
		mode => 
		{ 
			required => 1, 
			isa      => subtype( 'Str' => where { $_ =~ /<|>|>>/ } ), 
			default  => '>',
		}
		encoding =>
		{
			required => 1,
			isa      => 'Str',
			default  => 'utf-8',
		}
	],
	returns_does => 'Printable',
	execute => sub 
	{
		my ($filename, $mode, $encoding) = params;
		return IO::File->new($filename, "$mode:encoding($encoding)");
	}
);

function 'connect' =>
(
	params => 
	[
		dsn      => { isa => 'Str', required => 1 },
		username => { isa => 'Str', required => 1 },
		password => { isa => 'Str' },
		raise_error => 
		{
			qw(:required :named :option),
			isa     => 'Bool',
			default => 0,
			writer  => 'RaiseError',
		},
		auto_commit =>
		{
			qw(:required :named :option),
			isa     => 'Bool',
			default => 0,
			writer  => 'AutoCommit',
		},
	],
	returns => 'DBI::dbh',
	execute => sub
	{
		my ($dsn, $username, $password) = params(-args);
		my $opt = params(-options);

		if ($opt->raise_error)
		{
			...
		}
	},
);


param 'dsn' =>
(
	qw(:required :ro),
	isa => 'DSN', 
);

param 'username' =>
(
	qw(:requied :ro),
	isa => 'Username',
);

param 'password' =>
(
	qw(:required :ro),
	isa => 'Password',
);

param 'raise_error' => 
(
	qw(:required),
	isa      => 'Bool',
	default  => 0,
	init_arg => 'RaiseError',
);

param 'auto_commit' =>
(
	qw(:required),
	isa      => 'Bool',
	default  => 0,
	init_arg => 'AutoCommit',
);

function 'connect' =>
(
	params => [qw(dsn username password raise_error auto_commit)],
);

function 'connect' =>
(
	params => [
		qw(dsn username password),
		'+raise_error' => [qw(:required :named)],
		'+auto_commit' => [qw(:required :named)],
	],
	returns => 'DBI::dbh',
	execute => sub
	{
		...
	}
);
