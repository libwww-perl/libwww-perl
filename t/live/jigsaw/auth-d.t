use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('jigsaw.w3.org' => 80);

use HTTP::Request;
use LWP::UserAgent;

plan tests => 3;

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

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Digest/");
my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');

like($res->content, qr/Your browser made it!/, 'Proper response content');
is($res->header("Client-Response-Num"), 5, 'Client-Response-Num is 5');
