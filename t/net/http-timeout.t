use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use HTTP::Request;
use LWP::UserAgent;

if (!-e "$Bin/config.pl") {
    plan skip_all => 'no net config file';
    exit 0;
}

require "$Bin/config.pl";

plan tests => 6;

ok(defined $net::httpserver, 'net::httpserver exists');
ok(defined $net::cgidir, 'net::cgidir exists');
my $netloc = $net::httpserver || '';
my $script = ($net::cgidir || '') . "/timeout";
my $url = "http://$netloc$script";

my $ua = LWP::UserAgent->new;
$ua->timeout(4);
is($ua->timeout, 4, 'timeout set to 4 seconds');

my $request = HTTP::Request->new('GET', $url);

my $response = $ua->request($request, undef);
isa_ok($response, 'HTTP::Response', 'got a proper response object');

my $str = $response->as_string;

ok($response->is_error, 'is_error');
like($str, qr/timeout/, 'string contains timeout');
