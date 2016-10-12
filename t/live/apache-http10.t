use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('www.google.com' => 80);

use HTTP::Request;
use LWP::UserAgent;

plan tests => 2;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(HEAD => "http://www.google.com/");

$req->protocol("HTTP/1.0");

my $res = $ua->simple_request($req);
isa_ok($res, 'HTTP::Response', 'simple_request: Got a proper response');
is($res->protocol, 'HTTP/1.0', 'Request to google.com: Got an HTTP 1.0 response');
