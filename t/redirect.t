use strict;
use warnings;

# This is a regression test for #171

use Test::More;

# Test::RequiresInternet is used here basically just to SKIP tests if
# NO_NETWORK_TESTING has been enabled. We would want to do this particularly if
# there is a badly behaved router on the network where the tests are being run.
use Test::RequiresInternet;

use LWP::UserAgent ();

# Regarding the choice of 234.198.51.100 as a test IP address, please see
# https://tools.ietf.org/html/rfc6676
#
# RFC 5737 reserves the block 198.51.100.0/24 (TEST-NET-2) for use in
# documentation. However, some broken network setups may cause packets
# for TEST-NET-2 to be filtered and this test to fail.
#
# The chosen address 234.198.51.100 is a multicast address derived
# from TEST-NET-2. Since adjoining addresses might be valid addresses,
# this particular address is less likely to get filtered.

my $url = 'http://234.198.51.100/';

my $ua = LWP::UserAgent->new();

# default number of redirects
{
    $ua->timeout(1);
    my $res = $ua->get($url);
    like(
        $res->header("Client-Warning"),
        qr/Internal Response/i,
        'Timeout gives a client warning'
    );
    like(
        $res->content,
        qr/Can't connect/i,
        '... and has tells us about the problem'
    );
}

# no redirects
{
    $ua->timeout(1);
    $ua->max_redirect(0);
    my $res = $ua->get($url);
    like(
        $res->header("Client-Warning"),
        qr/Internal Response/i,
        'Timeout with no redirects gives a client warning'
    );
    like(
        $res->content,
        qr/Can't connect/i,
        '... and has tells us about the problem'
    );
}

done_testing();
