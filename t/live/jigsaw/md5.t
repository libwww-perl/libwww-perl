use strict;
use warnings;
use Test::More;

use Digest::MD5 qw(md5_base64);
use HTTP::Request;
use LWP::UserAgent;

plan tests => 7;

my $ua = LWP::UserAgent->new(keep_alive => 1);
isa_ok($ua, 'LWP::UserAgent', 'new: UserAgent instance');

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/h-content-md5.html");
isa_ok($req, 'HTTP::Request', 'new: HTTP::Request instance');
$req->header("TE", "deflate");

my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');

is($res->header('Content-MD5'), md5_base64($res->content).'==', 'Content-MD5 header matches content');

my $etag = $res->header("etag");
$req->header("If-None-Match" => $etag);

$res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
is($res->code, 304, 'response code: 304');
is($res->header('Client-Response-Num'), 2, 'Client-Response-Num header is 2');
