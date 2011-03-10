package TestParams;

use MooseX::Params;
use Data::Dumper::Concise;

param 'some_param' =>
(
	option => 'value',
	another => 'stuff',
);

method 'try_me' => sub 
{
	print "This is a plain sub!\n";
};

method 'basic_options' =>
(
	params => [qw(one two three)],
	sub 
	{
		my @params = params(qw(one three));
		print Dumper \@params;
	},
);

method 'try_execute' =>
(
	params  => [qw(one two three)],
	execute => sub { print "I work!!\n" },
);

method 'link' =>
(
	params =>
	[
		oldfile => { required => 1, isa => 'Str' },
		newfile => { required => 1, isa => 'Str' },
	],
	execute => sub
	{
		print "Old file: " . params('oldfile') . "\n";
		print "New file: " . params('newfile') . "\n";
	}
);

method 'mysay' =>
(
    params  => [ lines => { auto_deref => 1 } ],
    execute => sub { print "$_\n" for params('lines') },
);

no MooseX::Params;

1;
