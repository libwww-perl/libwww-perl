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

my $ua = LWP::UserAgent->new;

ok(defined $net::httpserver, 'net::httpserver exists');
ok(defined $net::cgidir, 'net::cgidir exists');
my $netloc = $net::httpserver || '';
my $script = ($net::cgidir || '') . "/test";
my $url = "http://$netloc$script?query";

my $request = HTTP::Request->new('GET', $url);

my $response = $ua->request($request, undef, undef);
isa_ok($response, 'HTTP::Response', 'got a proper response object');

my $str = $response->as_string;

ok($response->is_success, 'response successful');
like($str, qr/^REQUEST_METHOD=GET$/m, 'request method is GET');

like($str, qr/^QUERY_STRING=query$/m, 'query string is query');
