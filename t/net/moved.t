# perl

use strict;
use warnings;
use Test::More;
plan tests => 3;

require_ok("net/config.pl");
require_ok("LWP::UserAgent");

my $url = "http://$net::httpserver$net::cgidir/moved";
my $ua  = LWP::UserAgent->new;    # create a useragent to test
$ua->timeout(30);                 # timeout in seconds

my $request = HTTP::Request->new('GET', $url);

# print $request->as_string;

my $response = $ua->request($request, undef, undef);

ok($response->is_success, "\$response->is_success [$url]") or print $response->as_string;

# avoid -w warning
my $dummy = $net::httpserver;
   $dummy = $net::cgidir;
