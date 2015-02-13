#!/usr/local/bin/perl -w
#
# Check GET via HTTP.
#

use FindBin qw($Bin);
if (!-e "$Bin/config.pl") {
  print "1..0 # SKIP no net config file";
  exit 0;
}

require "$Bin/config.pl";
require HTTP::Request;
require LWP::UserAgent;

print "1..2\n";

my $ua = new LWP::UserAgent;    # create a useragent to test

$netloc = $net::httpserver;
$script = $net::cgidir . "/test";

$url = "http://$netloc$script?query";

my $request = new HTTP::Request('GET', $url);

print "GET $url\n\n";

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

print "$str\n";

if ($response->is_success and $str =~ /^REQUEST_METHOD=GET$/m) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}

if ($str =~ /^QUERY_STRING=query$/m) {
    print "ok 2\n";
}
else {
    print "not ok 2\n";
}

# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
