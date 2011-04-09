#!perl -w

use strict;
use Test;
plan tests => 1;

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;

require HTTP::Request;
my $req = HTTP::Request->new(TRACE => "http://www.apache.org/");
$req->protocol("HTTP/1.0");
my $res = $ua->simple_request($req);
ok($res->content, qr/HTTP\/1.0/);

$res->dump(prefix => "# ");
