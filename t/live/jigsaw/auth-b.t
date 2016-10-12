use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('jigsaw.w3.org' => 80);

use HTTP::Request;
use LWP::UserAgent;

plan tests => 9;

{
    package MyUA;
    use base 'LWP::UserAgent';

    my @try = (['foo', 'bar'], ['', ''], ['guest', ''], ['guest', 'guest']);

    sub get_basic_credentials {
        my ($self, $realm, $uri, $proxy) = @_;
        my $p = shift @try;
        return @$p;
    }
}

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Basic/");
my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
is($res->code, 401, 'Got a 401 response');

$req->authorization_basic('guest', 'guest');
is($req->authorization_basic(), 'guest:guest', 'authorization_basic: set properly');
$res = $ua->simple_request($req);
isa_ok($res, 'HTTP::Response', 'simple_request: Got a proper response');
is($res->code, 200, '200 response with basic auth');
like($res->content, qr/Your browser made it!/, 'good content with basic auth');

$ua = MyUA->new(keep_alive => 1);

$req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Basic/");
$res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');

like($res->content, qr/Your browser made it!/, 'good content');
is($res->header("Client-Response-Num"), 5, 'Client-Response-Num is 5');
