#!/usr/bin/perl -w
#
# Test retrieving a file with a 'ftp://' URL,
# via a HTTP proxy.
#

use FindBin qw($Bin);
if (!-e "$Bin/config.pl") {
  print "1..0 # SKIP no net config file";
  exit 0;
}

require "$Bin/config.pl";

print "1..1\n";

unless (defined $net::ftp_proxy) {
    print "not ok 1\n";
    exit 0;
}

require HTTP::Request;
require LWP::UserAgent;

my $ua = LWP::UserAgent->new;   # create a useragent to test

$ua->proxy('ftp', $net::ftp_proxy);

my $url = 'ftp://ftp.uninett.no/';

my $request = HTTP::Request->new('GET', $url);

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

if ($response->is_success) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}
