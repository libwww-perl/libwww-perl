#
# $Id: QuotedPrint.pm,v 1.9 1996/04/09 15:44:42 aas Exp $

package MIME::QuotedPrint;

=head1 NAME

encode_qp - Encode string using quoted-printable encoding

decode_qp - Decode quoted-printable string

=head1 SYNOPSIS

 use MIME::QuotedPrint;

 $encoded = encode_qp($decoded);
 $decoded = decode_qp($encoded);

=head1 DESCRIPTION

This module provides functions to encode and decode strings into the
Quoted-Printable encoding specified in RFC 1521 - I<MIME (Multipurpose
Internet Mail Extensions)>.  The Quoted-Printable encoding is intended
to represent data that largely consists of bytes that correspond to
printable characters in the ASCII character set.  Non-printable
characters (as defined by enghlish americans) are represented by a
triplet consisting of the character "=" followed by two hexadecimal
digits.

Note that the encode_qp() routine does not change newlines C<"\n"> to
the CRLF sequence even though this might be considered the right thing
to do (RFC 1521 (Q-P Rule #4)).

If you prefer not to import these routines into your namespace you can
call them as:

  use MIME::QuotedPrint ();
  $encoded = MIME::QuotedPrint::encode($decoded);
  $decoded = MIME::QuotedPrint::decode($encoded);

=head1 COPYRIGHT

Copyright 1995, 1996 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@sn.no>

=cut

require 5.002;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(encode_qp decode_qp);

$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

sub encode_qp ($)
{
    my $res = shift;
    $res =~ s/([^ \t\n!-<>-~])/sprintf("=%02X", ord($1))/eg;  # rule #2,#3
    $res =~ s/([ \t]+)$/
      join('', map { sprintf("=%02X", ord($_)) }
		   split('', $1)
      )/egm;                        # rule #3 (encode whitespace at eol)

    # rule #5 (lines must be shorter than 76 chars, but we are not allowed
    # to break =XX escapes.  This makes things complicated :-( )
    my $brokenlines = "";
    $brokenlines .= "$1=\n" while $res =~ s/^(.{74}([^=]{2})?)//;
    # unnessesary to make a break at the last char
    $brokenlines =~ s/=\n$// unless length $res;

    "$brokenlines$res";
}


sub decode_qp ($)
{
    my $res = shift;
    $res =~ s/\s+(\r?\n)/$1/g; # rule #3 (trailing white space must be deleted)
    $res =~ s/=\r?\n//g;       # rule #5 (soft line breaks)
    $res =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
    $res;
}

# Set up aliases so that these functions also can be called as
#
# MIME::QuotedPrint::encode();
# MIME::QuotedPrint::decode();

*encode = \&encode_qp;
*decode = \&decode_qp;

1;
