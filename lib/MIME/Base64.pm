#
# $Id: Base64.pm,v 1.1 1995/08/23 08:28:14 aas Exp $

package MIME::Base64;

=head1 NAME

base64_encode - Encode string using base64 encoding

base64_decode - Decode base64 string

=head1 SYNOPSIS

 use MIME::Base64;
 
 $encoded = base64_encode('Aladdin:open sesame');
 $decoded = base64_decode($encoded);

=head1 DESCRIPTION

This module provides functions to encode and decode strings into the
Base64 encoding specified in RFC 1521 - I<MIME (Multipurpose Internet
Mail Extensions)>.

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>, based on LWP::Base64 written by Martijn
Koster <m.koster@nexor.co.uk> and Joerg Reichelt <j.reichelt@nexor.co.uk>

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(base64_encode base64_decode);

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

use integer;

sub base64_encode
{
    my $res = "";
    while ($_[0] =~ /(.{1,45})/gs) {
	$res .= substr(pack('u', $1), 1);
	chop($res);
    }
    $res =~ tr| -_|A-Za-z0-9+/|;
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    $res;
}


sub base64_decode
{
    local($^W) = 0; # unpack("u",...) gives bogus warning in 5.001m

    my $str = shift;
    my $res = "";
   
    $str =~ tr|A-Za-z0-9+/||cd;             # remove non-base64 chars (padding)
    $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
    while ($str =~ /(.{1,60})/gs) {
	my $len = chr(32 + length($1)*3/4); # compute length byte
	$res .= unpack("u", $len . $1 );    # uudecode
    }
    $res;
}

1;
