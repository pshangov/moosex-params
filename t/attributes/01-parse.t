use strict;
use warnings;

use MooseX::Params::Util::Parameter;
use Devel::Dwarn;

my @specs = MooseX::Params::Util::Parameter::parse_params_attribute(q{
    Str test, 
    &ArrayRef[Int] number?, 
    :simple, 
    count ~ _build_count(), 
    string = 'hdfdd\n!!llo', 
    Int :outcome(result) = 5,
    :(calc)~
});

Dwarn \@specs;
