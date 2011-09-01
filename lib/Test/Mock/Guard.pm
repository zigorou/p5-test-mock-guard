package Test::Mock::Guard;

use strict;
use warnings;

use Exporter qw(import);
use Class::Load qw(load_class);
use List::Util qw(max);

our $VERSION = '0.02';
our @EXPORT_OK = qw(mock_guard);

sub mock_guard {
    my %class_defs = @_;
    return Test::Mock::Guard->new( %class_defs );
}

my $stash = +{};
sub new {
    my ( $class, %class_defs ) = @_;
    my $restore = +{};
    for my $class_name ( keys %class_defs ) {
        load_class $class_name;
        $stash->{$class_name} ||= +{};
        $restore->{$class_name} = +{};
        my $method_defs = $class_defs{$class_name};
        for my $method_name ( keys %$method_defs ) {
            _stash($class_name, $method_name, $restore);
            my $mocked_method = ref $method_defs->{$method_name} eq 'CODE'
                ? $method_defs->{$method_name}
                : sub { $method_defs->{$method_name} };
            no strict 'refs';
            no warnings 'redefine';
            *{"$class_name\::$method_name"} = $mocked_method;
        }
    }
    return bless +{ restore => $restore } => $class;
}

sub _stash {
    my ($class_name, $method_name, $restore) = @_;
    $stash->{$class_name}{$method_name} ||= {
        counter      => 0,
        restore      => +{},
        delete_flags => +{},
    };
    my $index = ++$stash->{$class_name}{$method_name}{counter};
    $stash->{$class_name}{$method_name}{restore}{$index} = $class_name->can($method_name);
    $restore->{$class_name}{$method_name} = $index;
}

sub DESTROY {
    my $self = shift;
    while ( my ( $class_name, $method_defs ) = each %{$self->{restore}} ) {
        for my $method_name ( keys %$method_defs ) {
            my $stuff = $stash->{$class_name}{$method_name};
            my $index = $method_defs->{$method_name};
            if ($index < max keys %{$stuff->{restore}}) {
                $stuff->{delete_flags}{$index} = 1; # fix: destraction problem
            }
            else {
                my $orig_method = delete $stuff->{restore}{$index}; # current restore method

                # restored old mocked method
                for my $index (sort keys %{$stuff->{delete_flags}}) {
                    delete $stuff->{delete_flags}{$index};
                    $orig_method = delete $stuff->{restore}{$index};
                }

                # cleanup
                unless (keys %{$stuff->{restore}}) {
                    delete $stash->{$class_name}{$method_name};
                }

                no strict 'refs';
                no warnings 'redefine';
                *{"$class_name\::$method_name"} = $orig_method
                    || *{"$class_name\::$method_name is unregistered"}; # black magic!
            }
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
