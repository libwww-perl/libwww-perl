# -*- perl -*-
#
# Test mirroring a file
#

use strict;
use warnings;
use HTTP::Status;
use Test::More;
use FindBin qw($Bin);

plan skip_all => 'No net config file' unless -e "$Bin/config.pl";

require_ok("$Bin/config.pl");
use_ok('LWP::UserAgent');

ok($net::httpserver, 'httpserver set in config.pl');
ok($net::cgidir, 'cgidir set in config.pl');

my $ua = LWP::UserAgent->new;   # create a useragent to test
isa_ok($ua,'LWP::UserAgent', 'new UserAgent');

my $url  = "http://$net::httpserver/$net::cgidir/mirror";
my $copy = "lwp-test-$$"; # downloaded copy

my $response = $ua->mirror($url, $copy);
isa_ok($response, 'HTTP::Response', 'got a proper response.');

ok(HTTP::Status::is_success($response->code), '$response->code OK');

sleep 1;  # we want to test the file at a later time

# OK, so now do it again, should get Not-Modified
$response = $ua->mirror($url, $copy);
is($response->code, &HTTP::Status::RC_NOT_MODIFIED, '$response->code NOT_MODIFIED') or print $response->as_string;

unlink($copy);
ok( !-f $copy, "Deleted our copy: $copy");

done_testing();
