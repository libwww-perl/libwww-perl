#!/usr/local/bin/perl -w
#
# Check POST via HTTP.
#

sub BEGIN {    unshift(@INC, '../lib'); }

require LWP::http;
require LWP::UserAgent;

$me = 'post-http';      # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL('http://web.nexor.co.uk/' .
                    'users/mak/cgi-bin/lwp-test.pl/as_string');


my $form = 'searchtype=Substring';

my $request = new LWP::Request('POST', $url, $form);

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

if ($response->isSuccess and $str =~ /REQUEST_METHOD = 'POST'/) {
    print "'$me' ok\n";
}
else {
    print "'$me' failed: " . $response->errorAsHTML . "\n";
}
