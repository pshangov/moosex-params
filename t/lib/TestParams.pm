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
	#print "This is it!\n";
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

no MooseXParam;

1;
