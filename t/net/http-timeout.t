#
# Check timeouts via HTTP.
#

use FindBin qw($Bin);
if (!-e "$Bin/config.pl") {
  print "1..0 # SKIP no net config file";
  exit 0;
}

require "$Bin/config.pl";
require HTTP::Request;
require LWP::UserAgent;

print "1..1\n";

my $ua = LWP::UserAgent->new;   # create a useragent to test

$ua->timeout(4);

$netloc = $net::httpserver;
$script = $net::cgidir . "/timeout";

$url = "http://$netloc$script";

my $request = HTTP::Request->new('GET', $url);

print $request->as_string;

my $response = $ua->request($request, undef);

my $str = $response->as_string;

print "$str\n";

if ($response->is_error and
    $str =~ /timeout/) {
    print "ok 1\n";
}
else {
    print "nok ok 1\n";
}

# avoid -w warning
$dummy = $net::httpserver;
$dummy = $net::cgidir;
