#!/usr/local/bin/perl -w
#
# Test retrieving a file with a 'ftp://' URL,
# via a HTTP proxy.
#

sub BEGIN {    unshift(@INC, '..'); }

require LWP::Debug;
require LWP::http;
require LWP::UserAgent;

LWP::Debug::level('+');

$me = 'get proxy';      # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->proxy('ftp', 'http://web.nexor.co.uk/');

my $url = new URI::URL('ftp://lancaster.nexor.co.uk/welcome.msg');

my $request = new LWP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

if ($response->isSuccess and $str =~ /This is the NEXOR public archive/) {
    print "'$me' ok\n";
}
else {
    print "'$me' failed: " . $response->errorAsHTML . "\n";
}
