#!/usr/local/bin/perl -w
#
# Check timeouts via HTTP.
#

use lib '..';

require LWP::StatusCode;
require LWP::http;
require LWP::UserAgent;

$me = 'timeout-http';   # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->timeout(5);

$url = new URI::URL('http://web.nexor.co.uk/' .
                    'users/mak/cgi-bin/timeout.pl');


my $request = new LWP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

if ($response->isError and 
    $response->code == &LWP::StatusCode::RC_REQUEST_TIMEOUT and 
    $str =~ /timeout/) {
    print "'$me' ok\n";
}
else {
    print "'$me' failed: " . $response->errorAsHTML . "\n";
}
