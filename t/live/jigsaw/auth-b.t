use strict;
use warnings;
use Test::More;

use HTTP::Request;
use LWP::UserAgent;

plan tests => 13;

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
isa_ok($ua, 'LWP::UserAgent', 'new: UserAgent instance');

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Basic/");
isa_ok($req, 'HTTP::Request', 'new: HTTP::Request instance');
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
isa_ok($ua, 'MyUA', 'new: MyUA instance');

$req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Basic/");
isa_ok($req, 'HTTP::Request', 'new: HTTP::Request instance');
$res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');

like($res->content, qr/Your browser made it!/, 'good content');
is($res->header("Client-Response-Num"), 5, 'Client-Response-Num is 5');
