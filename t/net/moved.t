#!/usr/local/bin/perl -w
#

use FindBin qw($Bin);
if (!-e "$Bin/config.pl") {
  print "1..0 # SKIP no net config file";
  exit 0;
}

require "$Bin/config.pl";
require LWP::UserAgent;

print "1..1\n";

$url = "http://$net::httpserver$net::cgidir/moved";

my $ua = new LWP::UserAgent;    # create a useragent to test
$ua->timeout(30);               # timeout in seconds

my $request = new HTTP::Request('GET', $url);

print $request->as_string;

my $response = $ua->request($request, undef, undef);

print $response->as_string, "\n";

if ($response->is_success) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}


# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
