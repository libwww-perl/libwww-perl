#!/usr/local/bin/perl -w
#
# Check GET via HTTP.
#

sub BEGIN {    unshift(@INC, '..'); }

require LWP::http;
require LWP::UserAgent;

$me = 'get-http';       # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL('http://web.nexor.co.uk/' .
                    'users/mak/cgi-bin/lwp-test.pl/as_string');


my $form = 'searchtype=Substring';

my $request = new LWP::Request('GET', $url, $form);

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

if ($response->isSuccess and $str =~ /REQUEST_METHOD = 'GET'/) {
    print "'$me' ok\n";
}
else {
    print "'$me' failed: " . $response->errorAsHTML . "\n";
}
