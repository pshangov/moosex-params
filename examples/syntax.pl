use strict;
use warnings;

package TestExecute;

use MooseX::Params::Signatures;

method foo => sub (bar) { $_{bar} };

warn foo('Kaboom');
