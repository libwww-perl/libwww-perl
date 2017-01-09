use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('jigsaw.w3.org' => 80);

use HTTP::Request;
use LWP::UserAgent;

plan tests => 2;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/neg");
$req->header(Connection => "close");

my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
is($res->code, 300, 'response code: 300');
