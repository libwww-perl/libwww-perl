use strict;
use warnings;
use Test::More;

use LWP::UserAgent;
plan tests => 4;

# This is a regression test for #171

my $ua = LWP::UserAgent->new();

{ # default number of redirects
    $ua->timeout(1);
    my $res = $ua->get('http://198.51.100.123/');
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

{ # no redirects
    $ua->timeout(1);
    $ua->max_redirect(0);
    my $res = $ua->get('http://198.51.100.123/');
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
