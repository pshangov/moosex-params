use MooseX::Params;

method test
    => params( qw(first second third) )
    => returns( scalar => 'Str', list => 'ArrayRef' )
    => execute
{
    return lc $_{first};
},
    => check
{
    return 1;
};

sub test
    :Param(first second third)
    :Private :Static :Method
    :Returns(ArrayRef)
    :Traits(Subcommand)
    :CmdFlag(test)
{

}


sub do_smth
{
	my ($self, %params) = validate
	(
		first  => { ... },
		second => { ... },
	);

}

sub do_smth
{
	my $self, %_ = params 
	(
		first  => { ... },
		second => { ... },
	);
}

sub _build_param_first
{
	my $self, %_ = params;
}

sub simple_sub
{
	my $self, %_ = params qw(first second);
}

sub doit 
	:Private :Memoized
	:Params(&Str *first! = _build_param_first, Int :count(number)?, ArrayRef[Sth] :collection?)
	:Returns(Array[Str])
{
	...	
}	

