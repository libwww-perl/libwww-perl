#!/usr/local/bin/perl -w
#
# Check receiving of some headers via HTTP.
# XXX Currently doesn't test anything
# (Need a CGI script for that), but is handy
# for manual inspection.
#

use lib '..';

require LWP::http;
require LWP::UserAgent;

$me = 'receiveHeaders-http';    # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL('http://web.nexor.co.uk/');

my $request = new LWP::Request('GET', $url, undef);
print $request->as_string;
my $response = $ua->request($request, undef, undef);
print $response->as_string;
if ($response->isSuccess) {
    print "'$me' unknown\n";
}
else {
    print "'$me' failed: " . $response->errorAsHTML . "\n";
}
