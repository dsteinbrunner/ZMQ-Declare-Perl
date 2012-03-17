package ZMQ::Declare::Types;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

use Moose::Util::TypeConstraints;
use JSON ();
use ZeroMQ::Constants qw(:all);

subtype 'ZMQDeclareUntypedSpecTree'
  => as 'HashRef';

coerce 'ZMQDeclareUntypedSpecTree'
  => from 'FileHandle'
    => via { JSON::decode_json(do {local $/; <$_>}) },
  => from 'ScalarRef[Str]'
    => via { JSON::decode_json($$_) },
  => from 'Str'
    => via {
        my $filename = $_;
        local $/;
        use autodie;
        open my $fh, "<", $filename;
        my $outhash = JSON::decode_json(<$fh>);
        close $fh;
        return $outhash;
    };

# TODO complete
my %socket_types = (
  ZMQ_PUB => ZMQ_PUB,
  ZMQ_SUB => ZMQ_SUB,
  ZMQ_PUSH => ZMQ_PUSH,
  ZMQ_PULL => ZMQ_PULL,
  ZMQ_UPSTREAM => ZMQ_UPSTREAM,
  ZMQ_DOWNSTREAM => ZMQ_DOWNSTREAM,
  ZMQ_REQ => ZMQ_REQ,
  ZMQ_REP => ZMQ_REP,
  ZMQ_PAIR => ZMQ_PAIR,
);
my %numeric_socket_types = reverse %socket_types;

enum 'ZMQDeclareSocketType' => [keys %socket_types];

subtype 'ZMQDeclareNumericSocketType'
  => as 'Int'
  => where {exists $numeric_socket_types{$_}};

coerce 'ZMQDeclareNumericSocketType'
  => from 'Str'
    => via {$socket_types{$_}};

sub sock_type_to_number {
  my $class = shift;
  return $socket_types{shift()};
}

enum 'ZMQDeclareSocketConnectType' => [qw(connect bind)];

1;
__END__

=head1 NAME

ZMQ::Declare::Types - Type definitions for ZMQ::Declare

=head1 SYNOPSIS

  use ZMQ::Declare;

=head1 DESCRIPTION

=head1 SEE ALSO

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut