# -*- perl -*-
#
# Test mirroring a file
#

use strict;
use warnings;
use Test::More;
plan tests => 5;

require_ok("net/config.pl");
require_ok("LWP::UserAgent");
require_ok("HTTP::Status");

my $ua   = new LWP::UserAgent;    # create a useragent to test
my $url  = "http://$net::httpserver/$net::cgidir/mirror";
my $copy = "lwp-test-$$"; # downloaded copy

my $response = $ua->mirror($url, $copy);

is($response->code, &HTTP::Status::RC_OK, '$response->code OK') or print $response->as_string;

sleep 1;  # we want to test the file at a later time

# OK, so now do it again, should get Not-Modified
$response = $ua->mirror($url, $copy);
is($response->code, &HTTP::Status::RC_NOT_MODIFIED, '$response->code NOT_MODIFIED') or print $response->as_string;
unlink($copy);
-f $copy and warn "Could not delete $copy!";

$net::httpserver = $net::httpserver;  # avoid -w warning
$net::cgidir     = $net::cgidir    ;  # avoid -w warning
