#
# $Id: QuotedPrint.pm,v 1.5 1995/10/31 09:11:26 aas Exp $

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
Internet Mail Extensions)>.

Note that these routines does not change C<"\n"> to CRLF.

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(encode_qp decode_qp);

$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

sub encode_qp
{
    my $res = shift;
    $res =~ s/([^ \t\n!-<>-~])/sprintf("=%02X", ord($1))/eg;  # rule #2,#3
    $res =~ s/([ \t]+)$/
      join('', map { sprintf("=%02X", ord($_)) }
	           split('', $1)
      )/egm;                        # rule #3 (encode whitespace at eol)

    # rule #5 (lines must be shorter than 76 chars, but we are not allowed
    # to break =XX escapes.  This makes things complicated.)
    my $brokenlines = "";
    $brokenlines .= "$1=\n" while $res =~ s/^(.{74}([^=]{2})?)//;
    # unnessesary to make a break at the last char
    $brokenlines =~ s/=\n$// unless length $res; 

    "$brokenlines$res";
}


sub decode_qp
{
    my $res = shift;
    $res =~ s/\s+(\r?\n)/$1/g; # rule #3 (trailing white space must be deleted)
    $res =~ s/=\r?\n//g;       # rule #5 (soft line breaks)
    $res =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
    $res;
}

1;
