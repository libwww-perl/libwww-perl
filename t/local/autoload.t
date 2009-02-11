#
# See if autoloading of protocol schemes work
#

use Test;
plan tests => 1;

require LWP::UserAgent;
# note no LWP::Protocol::file;

$url = "file:.";

require URI;
print "Trying to fetch '" . URI->new($url)->file . "'\n";

my $ua = new LWP::UserAgent;    # create a useragent to test
$ua->timeout(30);               # timeout in seconds

my $request = HTTP::Request->new(GET => $url);

my $response = $ua->request($request);
ok($response->is_success);
