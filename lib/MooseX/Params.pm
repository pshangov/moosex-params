package MooseX::Params;

# ABSTRACT: Subroutine signature declaration via attributes

use strict;
use warnings;
use 5.010;
use Attribute::Handlers;
use MooseX::Params::Util;
use MooseX::Params::Meta::Method;
use Moose::Meta::Class;
use Data::Printer;

sub import
{
    no strict 'refs';
    push @{caller.'::ISA'}, __PACKAGE__;
    use strict 'refs';
}

sub Args :ATTR(CODE,RAWDATA)
{
    my ($package, $symbol, $referent, $attr, $data) = @_;

    my ($name)  = $$symbol =~ /.+::(\w+)$/;
    my $coderef = \&$symbol;

    my $parameters = MooseX::Params::Util::inflate_parameters($package, $data);

    my $wrapped_coderef = MooseX::Params::Util::wrap_method($coderef, $package, $parameters);

    my $method = MooseX::Params::Meta::Method->wrap(
        $wrapped_coderef,
        name         => $name,
        package_name => $package,
        parameters   => $parameters,
    );

    Moose::Meta::Class->initialize($package)->add_method($name, $method);
}

sub BuildArgs :ATTR(CODE,RAWDATA) 
{
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my ($name)  = $$symbol =~ /.+::(\w+)$/;    
    $data = "_buildargs_$name" unless $data;

    my $method = Moose::Meta::Class->initialize($package)->get_method($name);
    $method->buildargs($data);
}

sub CheckArgs :ATTR(CODE,RAWDATA) 
{
    my ($package, $symbol, $referent, $attr, $data) = @_;
    my ($name)  = $$symbol =~ /.+::(\w+)$/;    
    $data = "_checkargs_$name" unless $data;

    my $method = Moose::Meta::Class->initialize($package)->get_method($name);
    $method->checkargs($data);
} 

1;

=pod

=head1 SYNOPSIS

  # in a module
  package MyModule 
  {
    use MooseX::Params;

    # any Moose types may be used for validation
    # positional arguments are by default required
    sub add :Args(Int first, Int second) {
        return $_{first} + $_{second};
    }

    # say add(2, 3);     # 5
    # say add(2);        # error
    # say add(2, 3, 4);  # error

    # @_ still works: you can ignore %_ if you want to
    sub add2 :Args(Int first, Int second) {
      my ($first, $second) = @_;
      return $first + $second;
    }

    # say add2(2, 3); # 5

    # '&' before a type constraint enables coercion
    subtype 'HexNum',
      as 'Str',
      where { /[a-f0-9]/i };

    coerce 'Int',
      from 'HexNum',
      via { hex $_ };

    sub add3 :Args(&Int first, &Int second) {
      return $_{first} + $_{second};
    }

    # say add3('A', 'B'); # 21

    # slurpy arguments consume the remainder of @_
    sub sum :Args(ArrayRef[Int] *values) :Export(:DEFAULT) {
	  my $sum = 0;
	  
      foreach my $value (@{$_{values}})
      {
	    $sum += $value;
	  }
	
      return $sum;
    }

    # say sum(2, 3, 4, 5); # 14
    
    # 'all' is optional:
    # if not present search the text within a file and return 1 if found, 0 if not
    # if present search the text and return number of lines in which text is found
    sub search2 Args:(text, file, all?) {
      open ( my $fh, $_{file}, '>' ) or die $!;
	  my $cnt = 0;
	  
      while (my $line = <$fh>)
      {
	    if ( index($line, $_{text}) > -1 )
        {
          return 1 if not $_{all};
		  $cnt++;
	    }
	  } 

      return $cnt;
    }

    # named arguments
    sub foo :Args(a, :b)
    {
      return $_{a} + $_{b} * 2;
    }

    # say foo( 3, b => 2 ); # 7
    # say foo(4, 9);        # error
    # say foo(2);           # error
    # say foo(2, 3, 4);     # error
    
    # parameters are immutable, assign to a variable to edit
    sub trim :Args(Str string)
    {
        my $string = $_{string};
        $string =~ s/^\s*//;
        $string =~ s/\s*$//;
        return $string;
    }
   
  }
    
  # in a class
  package User
  {
    use Moose;
    use MooseX::Params;
    use DateTime;
    
    extends 'Person';

    has 'password' => (
      is  => 'rw',
      isa => 'Str',
    );

    has 'last_login' => (
      is      => 'rw',
      isa     => 'DateTime',
    );

    # note the shortcut invocant syntax
    sub login :Args(self: Str pw)
    {
      return 0 if $_{pw} ne $_{self}->password;

      $_{self}->last_login( DateTime->now() );

      return 1;
    }
  
  }

  # parameters can have simple defaults
  sub find_clothes :Args(:size = 'medium', :color = 'white') { ... }

  # or builders for more complex tasks
  sub find_clothes :Args(
    :size   = _build_param_size,
    :color  = _build_param_color,
    :height = 170 )
  { ... }

  sub _build_param_color
  {
      return (qw(red green blue))[ int( rand 3 ) ];
  }

  # you can access all other parameters within a builder
  sub _build_param_size
  {
      return $_{height} > 200 ? 'large' : 'medium';
  }

  # buildargs
  
  package TemplateProcessor 
  {
    use MooseX::Params;
    use Data::Dumper;

    sub process_template
      :Args(input, output, params)
      :BuildArgs(_buildargs_process_template)
    {
	  say "open $_{input}";
	  say "replace " . Dumper $_{params};
	  say "save $_{output}";
    }
    
    # if 'output' is not provided, deduct it from input filename
    sub _buildargs_process_template
    {
      if (@_ == 2) {
        my ($input, $params) = @_;
        my $output = $input;
        substr($output, 0, -4, "html");
        return $input, $output, $params;
      } else {
        return @_;
      }
    }

  }

  my %data = (
	fname => "Foo",
	lname => "Bar",
  );

  process_template("index.tmpl", \%data);
  # open index.tmpl
  # replace {"lname" => "Bar", "fname" => "Foo"}
  # save index.html
  
  process_template("from.tmpl", "to.html", \%data);
  # open from.tmpl
  # replace {"lname" => "Bar", "fname" => "Foo"}
  # save to.html

  # checkargs
  sub process_person
      :Args(:first_name!, :last_name!, :country!, :ssn?)
      :CheckArgs # shortcut for :CheckArgs(_checkargs_${sub_name})
  { ... }

  sub _checkargs_process_person 
  {
      if ( $_{country} eq 'USA' ) 
      {
          die 'All US residents must have an SSN' unless $_{ssn};
      }
  }



