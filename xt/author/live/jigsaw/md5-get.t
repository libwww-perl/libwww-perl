use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('jigsaw.w3.org' => 443);

use Digest::MD5 qw(md5_base64);
use HTTP::Request;
use LWP::UserAgent;

my $tests = 5;
plan tests => $tests;

SKIP: {
    skip 'LIVE_JIGSAW_TESTS not enabled', $tests if $ENV{NO_JIGSAW};
    my $ua = LWP::UserAgent->new(keep_alive => 1);

    my $res = $ua->get(
        "https://jigsaw.w3.org/HTTP/h-content-md5.html",
        "TE" => "deflate",
    );
    isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
    is($res->header('Content-MD5'), md5_base64($res->content).'==', 'Content-MD5 header matches content');

    my $etag = $res->header("etag");
    $res = $ua->get(
        "https://jigsaw.w3.org/HTTP/h-content-md5.html",
        "TE" => "deflate",
        "If-None-Match" => $etag,
    );
    isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
    is($res->code, 304, 'response code: 304');
    is($res->header('Client-Response-Num'), 2, 'Client-Response-Num header is 2');
}
