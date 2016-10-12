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
my $script = ($net::cgidir || '') . "/test";
my $url = "http://$netloc$script";
my $form = 'searchtype=Substring';

my $ua = LWP::UserAgent->new;

my $request = HTTP::Request->new('POST', $url, undef, $form);
$request->header('Content-Type', 'application/x-www-form-urlencoded');

my $response = $ua->request($request, undef, undef);
isa_ok($response, 'HTTP::Response', 'got a proper response object');

my $str = $response->as_string;

ok($response->is_success, 'response successful');
like($str, qr/^REQUEST_METHOD=POST$/m, 'request method is POST');

ok($str =~ /^CONTENT_LENGTH=(\d+)$/m && $1 == length($form), 'right content length');
