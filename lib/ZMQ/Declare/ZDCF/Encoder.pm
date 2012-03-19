package ZMQ::Declare::ZDCF::Encoder;
use 5.008001;
use Moose;
our $VERSION = '0.01';

sub encode {
  die "encode() not implemented in base class";
}

sub decode {
  die "decode() not implemented in base class";
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::ZDCF::Encoder - ZDCF encoder base class

=head1 SYNOPSIS

  use ZMQ::Declare;

=head1 DESCRIPTION

Abstract base class for ZDCF encoders/decoders.

=head1 METHODS

=head2 encode

I<Not implemented in base class.>

Expects the data structure to encode as first argument. The data structure
is assumed to be a valid ZDCF tree.

Returns the ZDCF encoded as a string.

=head2 decode

I<Not implemented in base class.>

Expects a string to decode as first argument. Decodes the string
and returns a ZDCF tree (unvalidated).

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