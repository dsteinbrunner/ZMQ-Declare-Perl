package ZMQ::Declare::ZDCF;
use 5.008001;
use Moose;
our $VERSION = '0.01';

use ZMQ::Declare;
use ZMQ::Declare::ZDCF::Validator;
use ZMQ::Declare::ZDCF::Encoder;
use ZMQ::Declare::ZDCF::Encoder::JSON;

use ZeroMQ qw(:all);

use ZMQ::Declare::Constants qw(:all);
use ZMQ::Declare::Types;
use Carp ();
use Clone ();

has 'validator' => (
  is => 'ro',
  isa => 'ZMQ::Declare::ZDCF::Validator',
  default => sub {ZMQ::Declare::ZDCF::Validator->new},
);

has 'tree' => (
  is => 'rw',
  required => 1,
);

has 'encoder' => (
  is => 'rw',
  isa => 'ZMQ::Declare::ZDCF::Encoder',
  default => sub {ZMQ::Declare::ZDCF::Encoder::JSON->new},
);

sub BUILD {
  my $self = shift;
  my $tree = $self->tree;
  if (not ref($tree) eq 'HASH') {
    $tree = $self->encoder->decode($tree);

    Carp::croak("Failed to decode input ZDCF")
      if not defined $tree;
    Carp::croak("Failed to validate decoded ZDCF")
      if not $self->validator->validate($tree);

    $self->tree($tree);
  }
}

sub device {
  my $self = shift;
  my $name = shift;

  my $device = $self->_build_device($name);
  return $device;
}

sub _build_device {
  my ($self, $name) = @_;

  my $tree = $self->tree;
  Carp::croak("Invalid device '$name'")
    if $name eq 'context' or not exists $tree->{$name};

  my $dev_spec = $tree->{$name};
  my $typename = $dev_spec->{type};
  $typename = '' if not defined $typename;

  return ZMQ::Declare::Device->new(
    name => $name,
    spec => $self,
    typename => $typename,
  );
}

# runtime context
sub make_context {
  my ($self) = @_;
  my $tree = $self->tree;
  my $context_str = $tree->{context};
  my $iothreads = defined $context_str ? $context_str->{iothreads} : 1;
  my $cxt = ZeroMQ::Context->new($iothreads);
  return $cxt;
}

# runtime sockets
sub make_device_sockets {
  my $self = shift;
  my $dev_runtime = shift;

  my $tree = $self->tree;
  my $dev_spec = $tree->{ $dev_runtime->name };
  Carp::croak("Could not find ZDCF entry for device '".$dev_runtime->name."'")
    if not defined $dev_spec or not ref($dev_spec) eq 'HASH';

  my $cxt = $dev_runtime->context;
  my @socks;
  foreach my $sockname (grep $_ ne 'type', keys %$dev_spec) {
    my $sock_spec = $dev_spec->{$sockname};
    my $socket = $self->_setup_socket($cxt, $sock_spec);
    push @socks, [$socket, $sock_spec];
    $dev_runtime->sockets->{$sockname} = $socket;
  }

  $self->_init_sockets(\@socks, "bind");
  $self->_init_sockets(\@socks, "connect");

  return();
}

sub _setup_socket {
  my ($self, $cxt, $sock_spec) = @_;

  my $type = $sock_spec->{type};
  my $typenum = ZMQ::Declare::Types->zdcf_sock_type_to_number($type);
  my $sock = $cxt->socket($typenum);

  # FIXME figure out whether some of these options *must* be set after the connects
  my $opt = $sock_spec->{option} || {};
  foreach my $opt_name (keys %$opt) {
    my $opt_num = ZMQ::Declare::Types->zdcf_settable_sockopt_typee_to_number($opt_name);
    $sock->set_sockopt($opt_num, $opt->{$opt_name});
  }

  return $sock;
}

sub _init_sockets {
  my ($self, $socks, $connecttype) = @_;

  foreach my $sock_n_spec (@$socks) {
    my ($sock, $spec) = @$sock_n_spec;
    $self->_init_socket_conn($sock, $spec, $connecttype);
  }
}

sub _init_socket_conn {
  my ($self, $sock, $spec, $connecttype) = @_;

  my $conn_spec = $spec->{$connecttype};
  return if not $conn_spec;

  my @endpoints = (ref($conn_spec) eq 'ARRAY' ? @$conn_spec : $conn_spec);
  $sock->$connecttype($_) for @endpoints;
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::ZDCF - Object representing a 0MQ-declare specification

=head1 SYNOPSIS

  use ZMQ::Declare;

  my $zdcf = ZMQ::Declare::ZDCF->new(tree => $some_json_zdcf);
  # or:
  my $zdcf = ZMQ::Declare::ZDCF->new(
    encoder => ZMQ::Declare::ZDCF::Encoder::YourFormat->new,
    tree => $your_format_string.
  );

=head1 DESCRIPTION

=head1 SEE ALSO

The ZDCF RFC L<http://rfc.zeromq.org/spec:5>

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut