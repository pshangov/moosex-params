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
