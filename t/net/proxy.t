#!/usr/local/bin/perl -w
#
# Test retrieving a file with a 'ftp://' URL,
# via a HTTP proxy.
#

use strict;
use warnings;
use Test::More;
plan tests => 4;

require_ok("net/config.pl");
require_ok("HTTP::Request");
require_ok("LWP::UserAgent");

SKIP: {
    $net::ftp_proxy or skip('Set up $ftp_proxy in your net/config.pl file', 1);

    my $ua = new LWP::UserAgent;    # create a useragent to test

    $ua->proxy('ftp', $net::ftp_proxy);

    my $url      = 'ftp://ftp.uninett.no/';
    my $request  = HTTP::Request->new('GET', $url);
    my $response = $ua->request($request, undef, undef);
    my $str      = $response->as_string;

    ok($response->is_success, "\$response->is_success [$url]") or print $response->as_string;
}
