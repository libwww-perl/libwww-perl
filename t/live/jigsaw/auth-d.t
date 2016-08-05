use strict;
use warnings;
use Test::More;

use HTTP::Request;
use LWP::UserAgent;

plan tests => 5;

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

my $ua = MyUA->new(keep_alive => 1);
isa_ok($ua, 'MyUA', 'new: MyUA instance');

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Digest/");
isa_ok($req, 'HTTP::Request', 'new: HTTP::Request instance');
my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');

like($res->content, qr/Your browser made it!/, 'Proper response content');
is($res->header("Client-Response-Num"), 5, 'Client-Response-Num is 5');
