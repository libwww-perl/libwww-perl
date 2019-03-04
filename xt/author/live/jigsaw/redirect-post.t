use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('jigsaw.w3.org' => 80);

use HTTP::Request;
use LWP::UserAgent;
use JSON::PP qw(encode_json);
use Encode qw(encode_utf8);

plan tests => 10;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $data = {foo => 'bar', baz => 'quux'};
my $encoded_data = encode_utf8(encode_json($data));

# 307 not redirectable.
my $req = HTTP::Request->new('POST', "http://jigsaw.w3.org/HTTP/300/Go_307", undef, undef);
my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
is($res->code, 307, 'Got a 307 response');

push @{ $ua->requests_redirectable }, 'POST';

# POST can redirect, so support 307 (post to redirected location)
$res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: POST redirect got a proper response');
my $uri = $res->request->uri->as_string;
my $content = $res->content;

# first we POST to 307
unlike($uri, qr/Go_307/, 'POST to 307 endpoint was a POST');
unlike($content, qr/GET not implemented/, 'response was not a GET');

# we get redirected to 303
unlike($uri, qr/Go_303/, 'POST to 303 endpoint was a POST');
unlike($content, qr/GET not implemented/, 'response was not a GET');

# Go_303 returns a 303 header, so we must GET the redirected location here
like($uri, qr/303_ok\.html/, 'redirected to the correct page');
unlike($content, qr/POST not allowed on this resource/, '303 OK endpoint was not a POST');
like($content, qr/Your browser made it!/, 'response shows that we followed a 307 POST redirect and then a 303 GET redirect');
