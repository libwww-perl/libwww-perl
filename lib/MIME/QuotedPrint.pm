#
# $Id: QuotedPrint.pm,v 1.1 1995/08/23 08:28:15 aas Exp $

package MIME::QuotedPrintable;

=head1 NAME

qp_encode - Encode string using quoted-printable encoding

qp_decode - Decode quoted-printable string

=head1 SYNOPSIS

 use MIME::QuotedPrintable;
 
 $encoded = qp_encode($decoded);
 $decoded = qp_decode($encoded);

=head1 DESCRIPTION

This module provides functions to encode and decode strings into the
Quoted-Printable encoding specified in RFC 1521 - I<MIME (Multipurpose
Internet Mail Extensions)>.

Note that these routines does not change C<\n> to CRLF.

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(qp_encode qp_decode);

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

sub qp_encode
{
    $res = shift;
    $res =~ s/([^ \t\n!-<>-~])/sprintf("=%02X", ord($1))/eg;  # rule #2,#3
    $res =~ s/([ \t]+)$/
      join('', map { sprintf("=%02X", ord($_)) }
	           split('', $1)
      )/egm;                        # rule #3 (encode whitespace at eol)
    $res =~ s/(.{76})(?=.)/$1=\n/g; # rule #5 (lines shorter than 76 chars)
    $res;
}


sub qp_decode
{
    $res = shift;
    $res =~ s/\s+$//gm;  # rule #3 (any trailing white space must be deleted)
    $res =~ s/=\n$//;    # rule #5 (soft line breaks)
    $res =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
    $res;
}

1;
