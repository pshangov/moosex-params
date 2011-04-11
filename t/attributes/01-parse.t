use strict;
use warnings;

use MooseX::Params::Util::Parameter;
use Devel::Dwarn;

my @specs = MooseX::Params::Util::Parameter::parse_params_attribute('Str test, &Int number?, simple, count ~ _build_count(), string = "hdfdd!!llo", Int result = 5');
Dwarn \@specs;
