use strict;
use warnings;

use Test::Most;

{
    package TestExecute;
    use MooseX::Params::Interface::Attributes;

    sub test :Params(first, second, third)
    {
        return 1;
    }

    sub complex :Params(
        Str test, 
        &ArrayRef[Int] number, 
        :named(simple)?
    ) {
        return 1;
    }
}

#diag TestExecute::test();

ok 1;

done_testing();
