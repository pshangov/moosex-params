package MooseX::Params;

# ABSTRACT: Parameters with meta, laziness and %_

use strict;
use warnings;
use 5.10.0;
use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::Params::Meta::Method;
use MooseX::Params::Meta::Parameter;
use MooseX::Params::Util::Parameter;
use MooseX::Params::Magic::Wizard;
use Perl6::Caller;
use Package::Stash;

my $wizard = MooseX::Params::Magic::Wizard->new;

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
	with_meta => [qw(method)],
	also      => 'Moose',
    install   => [qw(unimport)]
);

sub import {
    my $frame = 1;
    my ($package_name, $method_name) =  caller($frame)->subroutine  =~ /^(.+)::(\w+)$/;

    my $stash = Package::Stash->new($package_name);
    $stash->add_symbol('$self', undef);

    goto &$import;
}

sub init_meta 
{
	shift;
	my %args = @_;
	Moose->init_meta(%args);
	Moose::Util::MetaRole::apply_metaroles(
		for => $args{for_class},
		class_metaroles => { class => ['MooseX::Params::Meta::Class'] },
	);
}

sub method
{
	my ( $meta, $name, @options ) = @_;

	my $stash = Package::Stash->new($meta->{package});
	my ($coderef, %options);

	if (!@options)
	{
		$options{execute} = "_execute_$name";
		$coderef = $stash->get_symbol('&' . $options{execute});
	}
	elsif (@options == 1 and ref $options[0] eq 'CODE')
	{
		$coderef = shift @options;
	}
	elsif (@options % 2 and ref $options[-1] eq 'CODE')
	{
		$coderef = pop @options;
		%options = @options;
		
		if ($options{execute})
		{
			Carp::croak("Cannot create method: we found both an 'execute' option and a trailing coderef");
		}
	}
	elsif (!(@options % 2))
	{
		%options = @options;
		
		if ( exists $options{execute} )
		{
			my $reftype = ref $options{execute};
			if (!$reftype)
			{
				$coderef = $stash->get_symbol('&' . $options{execute});
			}
			elsif ($reftype eq 'CODE')
			{
				$coderef = $options{execute};
			}
			else
			{
				Carp::croak("Option 'execute' must be a coderef, not $reftype");
			}
		}
		else
		{
            $options{execute} = "_execute_$name";
			$coderef = $stash->get_symbol('&' . $options{execute});
		}
	}
	else
	{
		Carp::croak("Cannot create method $name: invalid arguments");
	}

	my %parameters;
	if (%options)
	{
		if ($options{params})
		{
			if (ref $options{params} eq 'ARRAY')
			{
				%parameters = _inflate_parameters($meta->{package}, @{$options{params}});
			}
			#elsif ($options{params} eq 'HASH') { }
			else
			{
				Carp::croak("Argument to 'params' must be either an arrayref or a hashref");
			}
		}
	}

    my $prototype = delete $options{prototype};
    my $package_name = $meta->{package};
	# TODO execute later (after parameters are determined)
	my $wrapped_coderef = MooseX::Params::Util::Parameter::wrap($coderef, $package_name, \%parameters, $prototype);

	my $method = MooseX::Params::Meta::Method->wrap(
		$wrapped_coderef,
		name         => $name,
		package_name => $meta->{package},
		parameters   => \%parameters,
	);

    $meta->add_method($name, $method) unless defined wantarray;

    return $method;
}

sub _inflate_parameters
{
	my $package = shift;
	my @params = @_;
	my $position = 0;
	my @inflated_parameters;

	for ( my $i = 0; $i <= $#params; $i++ )
	{
		my $current = $params[$i];
		my $next = $i < $#params ? $params[$i+1] : undef;
		my $parameter;
		
		if (ref $next)
        # next value is a parameter specifiction
		{
			$parameter = MooseX::Params::Meta::Parameter->new(
				type    => 'positional',
				index   => $position,
				name    => $current,
				package => $package,
				%$next,
			);
			$i++;
		}
		else
		{
			$parameter = MooseX::Params::Meta::Parameter->new(
				type    => 'positional',
                index   => $position,
                name    => $current,
				package => $package,
			);
		}
		
		push @inflated_parameters, $parameter;
		$position++;
	}
	
	my %inflated_parameters = map { $_->name => $_ } @inflated_parameters;

	return %inflated_parameters;
}

### EXPERIMENTAL STUFF ###

# alternative syntax to define method body:
# execute 'method_name' => sub { ... };
sub execute
{
    my ($meta, $name, $coderef) = @_;

    my $old_method = $meta->remove_method($name);
    my $package_name = $old_method->package_name;
    my $wrapped_coderef = MooseX::Params::Util::Parameter::wrap($coderef, $package_name, $old_method->parameters);

    my $new_method = MooseX::Params::Meta::Method->wrap(
        $wrapped_coderef,
        name         => $name,
        package_name => $package_name,
        _delayed     => 0,
    );

    $meta->add_method($name, $new_method);
}

# define parameter definitions at class level, to be reused across methods
# param 'param_name' => ( ... );
sub param
{
	my ( $meta, $name, %options ) = @_;
	$meta->add_parameter($name);
}

# alternative syntax to access parameters
# my ($first, $second, $third) = params qw(first second third);
sub params
{
	my $meta = shift;
	my @parameters = @_;

  	my $frame = 3;
	my ($package_name, $method_name) =  caller($frame)->subroutine  =~ /^(.+)::(\w+)$/;
    
    #my $package_with_percent_underscore = 'MooseX::Params';
    my $package_with_percent_underscore = $package_name;


    my $stash = Package::Stash->new($package_with_percent_underscore);
    my %args = %{ $stash->get_symbol('%_') };

    # optionally dereference last requested parameter
    my $last_param = pop @parameters;
    my ($last_param_object) = $meta->get_method($method_name)->get_parameters_by_name($last_param);
    my @last_value = my $last_value = $args{$last_param};

    my $auto_deref;

    if ($last_param_object->auto_deref)
    {
        if ( ref $last_value eq 'HASH' )
        {
            @last_value = %$last_value;
            $auto_deref++;
        }
        elsif ( ref $last_value eq 'ARRAY' )
        {
            @last_value = @$last_value;
            $auto_deref++;
        }
    }

    my @all_values = ( @args{@parameters}, @last_value );

    if (@parameters == 0 and !$auto_deref)
    {
        return $last_value;
    }
    else
    {
        return @all_values;
    }
}

no Moose;

1;

=pod

=head1 SYNOPSIS

    package MySystem;

    use MooseX::Params;

    method 'login',
        params => [
            username => { required => 1, isa => 'Str' },
            password => { required => 1, isa => 'Str' },
        ], 
        sub {
            my $user = $self->load_user($_{username});
            $_{password} eq $user->password ? 1 : 0;
        };

    method 'load_user' ...

=head1 DESCRIPTION

This modules puts forward several proposals to evolve perl's method declaration and parameter processing syntax. For the original rationale see L<http://mechanicalrevolution.com/blog/parameter_apocalypse.html>.

The proposed interface is based on three cornerstone propositions:

=for :list
* Parameters are first-class entities that deserve their own meta protocol. A common meta protocol may be used by different implementations (e.g. this library, L<MooseX::Params::Validate>, L<MooseX::Method::Sigantures>) and allow them to coexist better. It is also the necessary foundation for more advanced features such as multimethods and extended role validation.
* Parameters should benefit from the same power and flexibility that L<Moose> attributes have. This module implements most of this functionality, including laziness.
* The global variable C<%_> is used as a placeholder for processed parameters. It is considered by the author of this module as an intuitive alternative to manual unpacking of C<@_> while staying within the limits of traditional Perl syntax.

=head1 DO NOT USE

This is an experimental module and has been uploaded to CPAN for showcase purposes only. It is incomplete, slow, buggy, and does not come with any maintenance guarantee. At this point it is not suitable for use in production environments.

=head1 METHODS

C<MooseX::Params> exports the C<method> keyword which is used to declare a new method. The simplest method declaration consists of a method name and code to execute:

    method do_something => sub { ... };

You can specify other options when declaring a method, but a trailing sub is always considered the method body:

    method do_something => (
        params => ... # declare parameters
        sub { ... }   # body
    );

The method body can also be explicitly specified via the C<execute> option:

    method do_something => (
        params  => ...         # declare parameters
        execute => sub { ... } # body
    );

This syntax allows for a method to have more than one executable parts (think C<BUILD> and C<BUILDARGS> for L<Moose> constructors):

    # pseudo code - 'buildargs' and 'build' are not implemented yet!
    method do_something => (
        params    => ...          # declare parameters
        buildargs => sub { ... }, # coerce a different signature
        build     => sub { ... }, # perform more complex checks
        execute   => sub { ... }, # body
    );

The C<execute> option can also point to the name of a subroutine to use as the method body:

    method do_something => (
        params  => ...
        execute => '_execute_do_something'
    );

    sub _execute_do_something { ... }

Actually if no method body is specified it will default to a sub named C<_execute_$method_name>:

    method 'do_something';

    sub _execute_do_something { ... }

=head1 PARAMETERS

=head2 Parameter names

Each parameter, whether passed in a named or positional fashion, has a name. The simplest parameter declaration looks like this:

    method do_something => (
        params => [qw(first second third)],
        sub { ... } 
    );

This declares a method with three positional parameters, called respectively C<first>, C<second> and C<third>. No validation or processing options have been specified for these parameters. You can now execute this method as:

    $self->do_something($first_argument, $second_argument, $third_argument);

=head2 C<%_> and C<$self>

This module takes a somewhat radical approach to accessing method parameters. It introduces two global variables in the using module's namespace: C<%_> and C<$self>. Within a method body, C<$self> is always localized to the method's invocant. The special C<%_> hash contains the processed values of all parameters passed to the method:
    
    has separator => ( is => 'ro', isa => 'Str', default => ',' );
    
    method print_something => (
        params => [qw(first second third)],
        sub { print join $self->separator, @_{qw(first second third)} } 
    );

Note that C<%_> is a read-only hash: any attempt to assign values to it will currently throw an exception. An exception will also be thrown if you attempt to access an element whose key is not a valid parameter name. C<@_> is also available if you want to do traditional-style unpacking of your parameters.

The downside of the current implementation is that functions called from within your method may access their caller's C<$self> and C<%_> variables (this is not impossible to remedy though).

=head2 Parameter processing

The main purpose of this module is to bring the full power of L<Moose> attributes to parameter processing. From the L<Moose> documentation:

    Moose attributes have many properties, and attributes are probably the single most powerful and flexible part of Moose.
    You can create a powerful class simply by declaring attributes. 
    In fact, it's possible to have classes that consist solely of attribute declarations.

Therefore, the parameter declaration API aims to mirror C<Moose>'s attribute API as close as possible:

    method 'login' => (
        params => [
            username => { required => 1, isa => 'Str' },
            password => { required => 1, isa => 'Str' },
        ], 
        sub {
            my $user = $self->load_user($_{username});
            $_{password} eq $user->password ? 1 : 0;
        }
    );

The following options are currently supported (most of them should be self-explanatory):

=for :list
* required
* isa
* coerce
* default
* builder
* lazy
* lazy_build
* documentation

Other options (e.g. traits, triggers, etc.) will be supported in the future.

=head2 Lazy building

Lazy building requires some explanation. As with L<Moose> attributes, the value of a parameter marked as lazy will not be processed until the first attempt to access it. This means that you can create parameters with expensive builders that will not execute if the code where they are called is never reached.


    method 'login' => (
        params => [
            username => { required => 1, isa => 'Str' },
            password => { required => 1, isa => 'Str' },
            user     => { lazy => 1, builder => '_build_param_user' },
        ], 
        sub {
            return unless $self->login_enabled;
            $_{password} eq $_{user}->password ? 1 : 0;
        }
    );

    sub _build_param_user { $self->load_user($_{username}) }

Within a parameter builder you can access C<$self> and C<%_> just as in the method body. C<%_> contains all parameters processed so far and is still read-only. The builder must return the value of the requested parameter.

The C<lazy_build> option is a shortcut for:

    required => 1, lazy => 1, builder => "_build_param_$param_name"

=head2 Named vs. positional

By default all parameters are positional. You can ask for named parameters via the C<type> option:

    method 'login' => (
        params => [
            username => { required => 1, isa => 'Str', type => 'named' },
            password => { required => 1, isa => 'Str', type => 'named' },
        ], 
        sub { ...  }
    );

    $self->login( username => $username, password => $password );

You can also mix named and positional parameters, as long as all positional parameters come first and are required:

    method 'login' => (
        params => [
            username => { required => 1, isa => 'Str', type => 'positional' },
            password => { required => 1, isa => 'Str', type => 'positional' },
            remember => { isa => 'Bool', type => 'named' },
            secure   => { isa => 'Bool', type => 'named' },
        ], 
        sub { ...  }
    );

    $self->login( $username, $password, remember => 1, secure => 0 );

More complex parameter passing styles are expected to be supported in the future (e.g. named parameters in a hashref).

=head1 META CLASSES

C<MooseX::Params> provides class, method and parameter metaroles, please see their sourcecode for detail (plain L<Moose>):

=for :list
* L<MooseX::Params::Meta::Class>
* L<MooseX::Params::Meta::Method>
* L<MooseX::Params::Meta::Parameter>

=head1 TODO

This module is still in its infancy. Some of the more important planned features include:

=for :list
* declaration of class-level parameters reusable across multiple methods
* return value validation
* multimethods
* C<BUILDARGS> and C<BUILD> for methods
* a C<function> keyword with similar syntax

Whether or not these features will be implemented depends mostly on the community response to the proposed API. Currently the best way to contribute to this module would be to provide feedback and commentary - the L<Moose> mailing list will be a good place for this.

=head1 SEE ALSO

=for :list
* L<MooseX::Params::Validate>
* L<MooseX::Method::Signatures>

=cut
