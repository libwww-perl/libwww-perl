#!/usr/local/bin/perl -w
#
# Check GET via HTTP.
#

use strict;
use warnings;
use Test::More;

plan(tests => 10);

require_ok("net/config.pl");
require_ok('HTTP::Request');
require_ok('LWP::UserAgent');

use vars qw/ $ua $request $response $str /;
my $netloc = $net::httpserver;
my $script = $net::cgidir . "/test";
my $url    = "http://$netloc$script?query";

ok($ua       = LWP::UserAgent->new(),           'LWP::UserAgent->new');    # create a useragent to test
ok($request  = HTTP::Request->new('GET', $url), "HTTP::Request->new('GET', '$url')");
ok($response = $ua->request($request),          '$r = $ua->request($request)');
ok($str      = $response->as_string,            '$r->as_string');

ok($response->is_success, '$r->is_success');
like($str, qr/^REQUEST_METHOD=GET$/m, 'REQUEST_METHOD');
like($str, qr/^QUERY_STRING=query$/m, 'QUERY_STRING');

my $dummy = $net::cgidir;       # avoid -w warning
   $dummy = $net::httpserver;   # avoid -w warning
