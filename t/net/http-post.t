#!/usr/local/bin/perl -w
#
# Check POST via HTTP.
#

print "1..2\n";

require LWP::Protocol::http;
require LWP::UserAgent;

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL('http://localhost/cgi-bin/test');

my $form = 'searchtype=Substring';

my $request = new HTTP::Request('POST', $url, undef, $form);

my $response = $ua->request($request, undef, undef);

my $str = $response->asString;

print "$str\n";

if ($response->isSuccess and $str =~ /^REQUEST_METHOD=POST$/m) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

if ($str =~ /^CONTENT_LENGTH=(\d+)$/m && $1 == length($form)) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}
