#!/usr/local/bin/perl -w
#

print "1..1\n";

require LWP::Debug;
require LWP::Protocol::file;
require LWP::Protocol::http;
require LWP::UserAgent;

$url = 'http://localhost/cgi-bin/lwp/moved';

#LWP::Debug::level('+trace');

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->timeout(30);               # timeout in seconds
$ua->useAlarm(1);               # don't use alarms
#$ua->useEval(0);               # don't eval, just die when thing go wrong
                                # (easier to read while debugging)

my $request = new HTTP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);

print $response->asString, "\n";

if ($response->isSuccess) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}

