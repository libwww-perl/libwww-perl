#!perl
#
# Check POST via HTTP.
#

use strict;
use warnings;
use Test::More;
plan tests => 7;

require_ok("net/config.pl");
require_ok("HTTP::Request");
require_ok("LWP::UserAgent");

my $netloc  = $net::httpserver;
my $script  = $net::cgidir . "/test";
my $url     = "http://$netloc$script";
my $form    = 'searchtype=Substring';
my $ua      = new LWP::UserAgent;    # create a useragent to test
my $request = new HTTP::Request('POST', $url, undef, $form);
$request->header('Content-Type', 'application/x-www-form-urlencoded');

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

ok($response->is_success, "\$response->is_success [$url]") or print "$str\n";
like($str, qr/^REQUEST_METHOD=POST$/m,  '/^REQUEST_METHOD=POST$/ ' . "[$url]");
$str =~ /^CONTENT_LENGTH=(\d+)$/m;
my $len = $1 || 0;
ok($len, '/^CONTENT_LENGTH=(\d+)$/ ' . "[$url]");
is($len, length($form), "CONTENT_LENGTH value [$url]");

# avoid -w warning
my $dummy = $net::httpserver;
   $dummy = $net::cgidir;
