package Test::Mock::Guard;

use strict;
use warnings;

use Exporter qw(import);
use Class::Load qw(load_class);

our $VERSION = '0.02';
our @EXPORT_OK = qw(mock_guard);

sub mock_guard {
    my %class_defs = @_;
    return Test::Mock::Guard->new( %class_defs );
}

sub new {
    my ( $class, %class_defs ) = @_;
    my $restore = +{};
    no warnings 'redefine';
    for my $class_name ( keys %class_defs ) {
        load_class $class_name;
        $restore->{$class_name} = +{};
        my $method_defs = $class_defs{$class_name};
        for my $method_name ( keys %$method_defs ) {
            my $mocked_method =
              ref $method_defs->{$method_name} eq 'CODE'
              ? $method_defs->{$method_name}
              : sub { $method_defs->{$method_name} };
            $restore->{$class_name}{$method_name} =
              $class_name->can($method_name);
	    no strict 'refs';
            *{"$class_name\::$method_name"} = $mocked_method;
        }
    }
    return bless +{ restore => $restore } => $class;
}

sub DESTROY {
    my $self = shift;
    no warnings 'redefine';
    while ( my ( $class_name, $method_defs ) = each %{$self->{restore}} ) {
	for my $method_name ( keys %$method_defs ) {
	    no strict 'refs';
            *{"$class_name\::$method_name"} = $method_defs->{$method_name};
        }
    }
}

1;
__END__

=head1 NAME

Test::Mock::Guard - Simple mock test library using RAII.

=head1 SYNOPSIS

  use Test::More;
  use Test::Mock::Guard qw(mock_guard);

  package Some::Class;

  sub new { bless {} => shift }
  sub foo { "foo" }
  sub bar { 1; }

  package main;

  {
      my $guard = mock_guard( 'Some::Class', +{ foo => sub { "bar" }, bar => 10 } );
      my $obj = Some::Class->new;
      is( $obj->foo, "bar" );
      is( $obj->bar, 10 );
  }

  my $obj = Some::Class->new;
  is( $obj->foo, "foo" );
  is( $obj->bar, 1 );

  done_testing;

=head1 DESCRIPTION

Test::Mock::Guard is mock test library using RAII.

=head1 EXPORT FUNCTION

=head2 mock_guard( %class_defs )

%class_defs are following format.

=over

=item key

Specify class name as mock

=item value

Hash reference. It's key as method name, It's value is code reference or value.
If the value is code reference, then call code reference and return the result.
If the value is value, then return the value directly.

=back

=head1 METHODS

=head2 new( %class_defs )

See L</mock_guard> definition.

=head2 DESTROY

Internal use only.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
