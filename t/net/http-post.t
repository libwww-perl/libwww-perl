#!/usr/local/bin/perl -w
#
# Check POST via HTTP.
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

$netloc = $net::httpserver;
$script = $net::cgidir . "/test";

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = "http://$netloc$script";

my $form = 'searchtype=Substring';

my $request = new HTTP::Request('POST', $url, undef, $form);
$request->header('Content-Type', 'application/x-www-form-urlencoded');

my $response = $ua->request($request, undef, undef);

my $str = $response->as_string;

print "$str\n";

if ($response->is_success and $str =~ /^REQUEST_METHOD=POST$/m) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}

if ($str =~ /^CONTENT_LENGTH=(\d+)$/m && $1 == length($form)) {
    print "ok 2\n";
}
else {
    print "not ok 2\n";
}

# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
