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

method test
    params( qw(first second third) )
    returns( scalar => 'Str', list => 'ArrayRef' )

    execute 
{
    return lc $_{first};
}
 
    check 
{
    return 1;
};

method test {
    
    param first  required => 1, isa => 'Int';
    param second required => 1, isa => 'Str';

    returns 'Str';

    buildargs 
    {
        ...
    }
    
    check
    {
        ...
    }

    execute
    {
        return 1;
    }
}

action release {
    
    path '/release';
    chained 'root';

    param test required => 1, isa => 'Str';

    formfu before_submit
    {
        ...
    }

    formfu after_submit
    {
        ...
    }
    
}

sub test
    :Param(first second third)
    :Private :Static :Method
    :Returns(ArrayRef)
    :Traits(Subcommand)
    :CmdFlag(test)
{

}

has something 
    :Ro 
    :Required 
    :Isa(Str) 
    :Default({ return 1 })
    :Traits(Bool Lazy);

method test
    :Private :Static :Method
    :Param(first second third)
    :Returns(ArrayRef)
    :Traits(Subcommand)
    :CmdFlag(test)
    :Buildargs
{
    ...
}
    :Build
{
    ...
}
    :Execute
{

};

sub something 
    :Attribute :Ro :Required :Lazy
    :Default( sub { return 1 } );

has something :Ro :Required :LazyBuild;

requires tests :Params :Returns(Array[Moose::Object]);

method do_something
    :Params
    :Returns(Array[Str])
{
    return 1;      
}

buildargs do_something 
{
    return 1;
}

check do_something
{
    return 1;
}

build :Has(something)
{ 
    return 1;
}

action release
    :Path
    :Chained
    :FormFu(submitted_and_valid) {
        return 1;
    } 
    :FormFu(before_submit)
    :FormFu( 
        before_submit => '',
        after_submit  => '',
    )
{
    
}

formfu :Action(release) :BeforeSubmit 
{
    return 1;
}

sub simple_method
{
    my ($self, %_) = params
    (
        first  => { required => 1, isa => 'Str' },
        second => { required => 1, isa => 'Int' },
    );


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
	:Params(&Str *first! = _build_param_first(), Int :count(number)?, ArrayRef[Sth] :collection?)
	:Returns(Array[Str])
{
	...	
}	

sub doit 
(
	first  => { isa => 'Str', required => 1 },
	second => { isa => 'Int', required => 1 },
)
	:Private :Memoized
	:Returs(Array[Str])
	:Traits(Subcommand)
	:Check(_check_doit)
{
	
	return 1;
}

sub doit 
	:Method 
	:Accepts( first  => { isa => 'Str', required => 1 },
		      second => { isa => 'Int', required => 1 } ) 
	:Returns( Array[Str] ) 
	:FormFu( before_submit => 'test_form', submited_and_valid => 'update' )
{
	...	
}
