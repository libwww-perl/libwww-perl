#
# $Id: Base64.pm,v 1.8 1995/08/22 18:03:32 aas Exp $

package LWP::Base64;

=head1 NAME

Base64encode - Encode string using base64 encoding

Base64decode - Decode string from base64 encoding

=head1 SYNOPSIS

 use LWP::Base64;
 
 $encoded = Base64encode('Aladdin:open sesame');
 $decoded = Base64decode($encoded);

=head1 DESCRIPTION

This package provides function to encode and decode strings into
Base64 encoding specified in RFC 1521 section 5.2, and used by HTTP
1.0 Basic Authentication.

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(Base64encode Base64decode);

$VERSION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

use integer;

sub Base64encode
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


sub Base64decode
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
