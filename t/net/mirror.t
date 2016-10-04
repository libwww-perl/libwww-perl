use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use LWP::UserAgent;

if (!-e "$Bin/config.pl") {
    plan skip_all => 'no net config file';
    exit 0;
}

require "$Bin/config.pl";

plan tests => 5;

ok(defined $net::httpserver, 'net::httpserver exists');
my $netloc = $net::httpserver || '';
my $url = "http://$netloc/";
my $copy = "lwp-test-$$"; # downloaded copy

my $ua = LWP::UserAgent->new;

my $response = $ua->mirror($url, $copy);
isa_ok($response, 'HTTP::Response', 'got a proper response object');

is($response->code, 200, 'response code 200');

# OK, so now do it again, should get Not-Modified
$response = $ua->mirror($url, $copy);
isa_ok($response, 'HTTP::Response', 'got a proper response object');
is($response->code, 304, 'response code 304');
unlink($copy);
