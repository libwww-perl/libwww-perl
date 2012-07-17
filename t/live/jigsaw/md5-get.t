# perl

use strict;
use warnings;
use Test::More;
plan tests => 6;

use_ok('LWP::UserAgent');
use_ok('Digest::MD5', qw(md5_base64));

my $ua  = LWP::UserAgent->new(keep_alive => 1);
my $res = $ua->get(
  "http://jigsaw.w3.org/HTTP/h-content-md5.html",
    "TE" => "deflate",
);

is($res->header("Content-MD5"), md5_base64($res->content) . "==", '$res->header("Content-MD5")') or
    print $res->as_string;

ok($res->header("etag"), '$res->header("etag")');

$res = $ua->get(
  "http://jigsaw.w3.org/HTTP/h-content-md5.html",
    "TE" => "deflate",
    "If-None-Match" => $res->header("etag")
);

is($res->code, 304, '$res->code is 304') or print $res->as_string;
is($res->header("Client-Response-Num"), 2, '$res->header("Client-Response-Num") is 2');
