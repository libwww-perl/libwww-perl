#
# Test retrieving a file with a 'ftp://' URL,
# via a HTTP proxy.
#

use strict;
use warnings;
use HTTP::Request;
use Test::More;
use FindBin qw($Bin);

plan skip_all => 'No net config file' unless -e "$Bin/config.pl";

use_ok('LWP::UserAgent');
require_ok("$Bin/config.pl");

ok($net::ftp_proxy, "ftp_proxy exists in config.pl");


SKIP: {
    $net::ftp_proxy or skip('Set up $ftp_proxy in your net/config.pl file', 1);

    my $ua = LWP::UserAgent->new;   # create a useragent to test
    $ua->proxy('ftp', $net::ftp_proxy);

    my $url      = 'ftp://ftp.uninett.no/';
    my $request = HTTP::Request->new('GET', $url);
    my $response = $ua->request($request, undef, undef);
    my $str      = $response->as_string;

    ok($response->is_success, "\$response->is_success [$url]") or print $response->as_string;
}

done_testing();
