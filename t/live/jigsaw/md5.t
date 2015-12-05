#!perl
use strict;
use warnings;

use Test::More;
plan(tests => 5);

use_ok('LWP::UserAgent');
use_ok('Digest::MD5', qw/md5_base64/);

my $ua  = LWP::UserAgent->new(keep_alive => 1);
my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/h-content-md5.html");
$req->header("TE", "deflate");

my $res = $ua->request($req);

is($res->header("Content-MD5"), md5_base64($res->content) . "==", '$res->header("Content-MD5")') or print $res->as_string;

my $etag = $res->header("etag");
$req->header("If-None-Match" => $res->header("etag"));

$res = $ua->request($req);

is($res->code, 304, '$res->code is 304') or print $res->as_string;
is($res->header("Client-Response-Num"), 2, '$res->header("Client-Response-Num") is 2');
