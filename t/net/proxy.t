#!/usr/local/bin/perl -w
#
# Test retrieving a file with a 'ftp://' URL,
# via a HTTP proxy.
#

print "1..1\n";

require LWP::Debug;
require LWP::Protocol::http;
require LWP::UserAgent;

#LWP::Debug::level('+');

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->proxy('ftp', 'http://web.nexor.co.uk/');

my $url = new URI::URL('ftp://lancaster.nexor.co.uk/welcome.msg');

my $request = new HTTP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);

my $str = $response->asString;

if ($response->isSuccess and $str =~ /This is the NEXOR public archive/) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}
