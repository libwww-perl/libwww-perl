#!/usr/local/bin/perl -w
#
# Simple get for quickie testing
#

sub BEGIN { unshift(@INC, '../lib'); }

require LWP::Debug;
require LWP::UserAgent;
# note no LWP::http;

$me = 'autoload';

$url = 'http://web.nexor.co.uk/users/mak/cgi-bin/lwp-test.pl/simple_html';

LWP::Debug::level('+trace'); # maximum logging

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->timeout(30);               # timeout in seconds
$ua->useAlarm(1);               # don't use alarms
$ua->useEval(0);                # don't eval, just die when thing go wrong
                                # (easier to read while debugging)

my $request = new LWP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);
if ($response->isSuccess) {
    print "'$me' ok\n";
}
else {
    print "'$me' failed: " . $response->errorAsHTML . "\n";
}

