#!/usr/local/bin/perl -w
#
# Test mirroring a file
#

use lib '..';

require LWP::Protocol::http;
require LWP::UserAgent;
require LWP::StatusCode;
require LWP::Debug;

$me = 'mirror-http';    # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

my $url = 'http://web.nexor.co.uk/';
my $copy = "/usr/tmp/lwp-test-$$"; # downloaded copy

my $response = $ua->mirror($url, $copy);

if ($response->code != &LWP::StatusCode::RC_OK) {
    die "'$me' failed first time round: \n" . $response->asString;
}

#&LWP::Debug::level('+');

# OK, so now do it again, should get Not-Modified

$response = $ua->mirror($url, $copy);
if ($response->code != &LWP::StatusCode::RC_NOT_MODIFIED) {
    die "failed second time round\n", $response->asString;
}
print "$me ok\n";
