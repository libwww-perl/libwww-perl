use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('jigsaw.w3.org' => 80);

use LWP::UserAgent;

plan tests => 2;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $res = $ua->get(
    "http://jigsaw.w3.org/HTTP/neg",
    Connection => "close",
);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
is($res->code, 300, 'response code: 300');
