package ZMQ::Declare::ZDCF::Validator;
use 5.008001;
use Moose;
our $VERSION = '0.01';

use Data::Rx;

my $context_schema =  { # the top level context obj/hash
  type => '//rec',
  optional => { # can have these properties
    iothreads => { type => '//int', range => {min => 1} },
    verbose => '//bool',
  },
};
my $option_schema = {
  type => '//rec',
  optional => {
    "hwm"          => { type => '//int' },
    "swap"         => { type => '//int' },
    "affinity"     => { type => '//int' },
    "identity"     => { type => '//str' },
    "subscribe"    => { type => '//str' },
    "rate"         => { type => '//int' },
    "recovery_ivl" => { type => '//int' },
    "mcast_loop"   => { type => '//bool' },
    "sndbuf"       => { type => '//int' },
    "rcvbuf"       => { type => '//int' },
  },
};
my $string_or_value_ary_schema = {
  type => '//any',
  of => [
    { type => '//str' },
    { type => '//arr', length => {min => 1}, contents => "//str" },
  ]
};
my $socket_type_schema = {
  type => '//any',
  of => [
    map {
      { type => '//str', value => $_ },
      { type => '//str', value => uc($_) }
    } qw(sub pub req rep xreq xrep push pull pair)
  ]
};
my $socket_schema = {
  type => '//any',
  of => [
    {
      type => '//rec',
      required => {
        type => $socket_type_schema,
        bind => $string_or_value_ary_schema,
      },
      optional => {
        connect => $string_or_value_ary_schema,
        option => $option_schema,
      },
    },
    {
      type => '//rec',
      required => {
        type => $socket_type_schema,
        connect => $string_or_value_ary_schema,
      },
      optional => {
        bind => $string_or_value_ary_schema,
        option => $option_schema,
      },
    }
  ]
};
my $device_schema = {
  type => '//rec',
  required => { 'type' => {type => '//str'} }, # device must have property called 'type'
  rest => {type => '//map', values => $socket_schema}, # anything else is a socket (sigh)
};
my $zdcf_schema = {
  type => '//rec',
  optional => { context => $context_schema },
  rest => {type => '//map', values => $device_schema}, # anything but the context is a device
};

my $rx = Data::Rx->new;
#my $validator_schema = $rx->make_schema($device_schema);
my $validator_schema = $rx->make_schema($zdcf_schema);

sub validate {
  my $self = shift;
  return $validator_schema->check(shift);
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::ZDCF::Validator - ZDCF validator

=head1 SYNOPSIS

  use ZMQ::Declare;
  my $validator = ZMQ::Declare::ZDCF::Validator->new;
  unless ($validator->check($datastructure)) {
    die "Input data structure is not ZDCF!"
  }

=head1 DESCRIPTION

Validates that a given nested Perl data structure (arrays, hashes, scalars)
is actually a valid ZDCF tree.

=head1 METHODS

=head2 validate

Returns true if the given Perl data structure is a valid ZDCF tree, false
otherwise.

=head1 SEE ALSO

The ZDCF RFC L<http://rfc.zeromq.org/spec:5>

L<Data::Rx>

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
