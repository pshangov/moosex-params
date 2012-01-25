package MooseX::Params::Meta::TypeConstraint::Listable;

use strict;
use warnings;

use Moose;
BEGIN { extends 'Moose::Meta::TypeConstraint::Parameterizable' }

__PACKAGE__->meta->add_attribute('listable' => (
    reader => 'listable',
));

1;
