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

plan tests => 3;

ok(defined $net::ftp_proxy, 'net::ftp_proxy exists');

my $ua = LWP::UserAgent->new;
$ua->proxy('ftp', $net::ftp_proxy);

my $url = 'ftp://ftp.uninett.no/';

my $request = HTTP::Request->new('GET', $url);

my $response = $ua->request($request, undef, undef);
isa_ok($response, 'HTTP::Response', 'got a proper response object');

ok($response->is_success, 'is_success');
