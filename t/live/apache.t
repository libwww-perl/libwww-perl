#!perl -w

use strict;
use Test;
plan tests => 6;

use Net::HTTP;


my $s = Net::HTTP->new(Host => "www.apache.org",
		       KeepAlive => 1,
		       Timeout => 15,
		       PeerHTTPVersion => "1.1",
		       MaxLineLength => 512) || die "$@";

for (1..2) {
    $s->write_request(TRACE => "/libwww-perl",
		      'User-Agent' => 'Mozilla/5.0',
		      'Accept-Language' => 'no,en',
		      Accept => '*/*');

    my($code, $mess, %h) = $s->read_response_headers;
    print "# $code $mess\n";
    for (sort keys %h) {
	print "# $_: $h{$_}\n";
    }
    print "\n";

    ok($code, "200");
    ok($h{'Content-Type'}, "message/http");

    my $buf;
    while (1) {
        my $tmp;
	my $n = $s->read_entity_body($tmp, 20);
	last unless $n;
	$buf .= $tmp;
    }
    $buf =~ s/\r//g;

    ok($buf, <<EOT);
TRACE /libwww-perl HTTP/1.1
Host: www.apache.org
User-Agent: Mozilla/5.0
Accept-Language: no,en
Accept: */*

EOT
}

