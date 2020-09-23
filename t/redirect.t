use strict;
use warnings;

# This is a regression test for #171

use Test::More;

# Test::RequiresInternet is used here basically just to SKIP tests if
# NO_NETWORK_TESTING has been enabled. We would want to do this particularly if
# there is a badly behaved router on the network where the tests are being run.
use Test::RequiresInternet;

use LWP::UserAgent ();

# Regarding the choice of 198.51.100.123 as a test IP address, please see
# https://tools.ietf.org/html/rfc5737
#
# The RFC contains the following description for the block to which this
# address belongs:
#
# Documentation Address Blocks
#
# The blocks 192.0.2.0/24 (TEST-NET-1), 198.51.100.0/24 (TEST-NET-2), and
# 203.0.113.0/24 (TEST-NET-3) are provided for use in documentation.

my $url = 'http://198.51.100.123/';

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
