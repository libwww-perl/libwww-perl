use strict;
use warnings;
use Test::More;

use LWP::UserAgent;

plan tests => 3;

my $ua = LWP::UserAgent->new(keep_alive => 1);
isa_ok($ua, 'LWP::UserAgent', 'new: UserAgent instance');

my $res = $ua->get(
    "http://jigsaw.w3.org/HTTP/neg",
    Connection => "close",
);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
is($res->code, 300, 'response code: 300');
