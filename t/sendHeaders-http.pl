#!/usr/local/bin/perl -w
#
# Check sending of some headers via HTTP.
# XXX Currently doesn't test anything
# (Need a CGI script for that), but is handy
# for manual inspection.
#

use lib '..';

require LWP::Protocol::http;
require LWP::UserAgent;

$me = 'sendHeaders-http';       # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL('http://web.nexor.co.uk:9999/');

my $request = new LWP::Request('GET', $url, undef);

# set some standard and non-standard fields,
# in random order
$request->header('Newbie', q!Didn't expect this huh?!);
$request->header('Accept', ['text/html', 'text/plain']);
$request->pushHeader('Accept', 'image/gif');
$request->header('User-Agent', 'lwp-test/0.1');

my $response = $ua->request($request, undef, undef);
if ($response->isSuccess) {
    print "'$me' unknown\n";
}
else {
    print "'$me' failed: " . $response->errorAsHTML . "\n";
}
