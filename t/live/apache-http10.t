use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('www.apache.org' => 80);

use HTTP::Request;
use LWP::UserAgent;

plan tests => 4;

my $ua = LWP::UserAgent->new;
isa_ok($ua, 'LWP::UserAgent', 'new: UserAgent instance');
my $req = HTTP::Request->new(TRACE => "http://www.apache.org/");
isa_ok($req, 'HTTP::Request', 'new: HTTP::Request instance');

$req->protocol("HTTP/1.0");

my $res = $ua->simple_request($req);
isa_ok($res, 'HTTP::Response', 'simple_request: Got a proper response');
like($res->content, qr/HTTP\/1.0/, 'Request to apache.org: Got an HTTP 1.0 response');
