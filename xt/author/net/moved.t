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

plan tests => 5;

ok(defined $net::httpserver, 'net::httpserver exists');
ok(defined $net::cgidir, 'net::cgidir exists');
my $netloc = $net::httpserver || '';
my $script = ($net::cgidir || '') . "/moved";
my $url = "http://$netloc$script";

my $ua = LWP::UserAgent->new;
$ua->timeout(30);
is($ua->timeout(), 30, 'timeout set to 30 seconds');

my $request = HTTP::Request->new('GET', $url);

my $response = $ua->request($request, undef, undef);
isa_ok($response, 'HTTP::Response', 'got a proper response object');

ok ($response->is_success, 'is_success');
