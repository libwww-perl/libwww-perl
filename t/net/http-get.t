#!/usr/local/bin/perl -w
#
# Check GET via HTTP.
#

print "1..1\n";

require LWP::Protocol::http;
require LWP::UserAgent;

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL('http://web.nexor.co.uk/' .
                    'users/mak/cgi-bin/lwp-test.pl/as_string');


my $form = 'searchtype=Substring';

my $request = new LWP::Request('GET', $url, undef, $form);

my $response = $ua->request($request, undef, undef);

my $str = $response->asString;

if ($response->isSuccess and $str =~ /REQUEST_METHOD = 'GET'/) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}
