#!/usr/local/bin/perl -w
#

print "1..1\n";

require "net/config.pl";
require LWP::Debug;
require LWP::UserAgent;

$url = "http://$net::httpserver$net::cgidir/moved";

#LWP::Debug::level('+trace');

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->timeout(30);               # timeout in seconds
$ua->useAlarm(1);               # don't use alarms
#$ua->useEval(0);               # don't eval, just die when thing go wrong
                                # (easier to read while debugging)

my $request = new HTTP::Request('GET', $url);

print $request->asString;

my $response = $ua->request($request, undef, undef);

print $response->asString, "\n";

if ($response->isSuccess) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}


# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
