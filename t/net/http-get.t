#!/usr/local/bin/perl -w
#
# Check GET via HTTP.
#

print "1..1\n";

require LWP::Protocol::http;
require LWP::UserAgent;

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL('http://localhost/cgi-bin/test');

my $request = new HTTP::Request('GET', $url);

print "GET $url\n\n";

my $response = $ua->request($request, undef, undef);

my $str = $response->asString;

print "$str\n";

if ($response->isSuccess and $str =~ /^REQUEST_METHOD=GET$/m) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}
