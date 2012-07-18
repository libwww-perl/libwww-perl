#!perl

use strict;
use warnings;
use Test::More;
plan tests => 3;

use_ok('LWP::UserAgent');
require_ok('HTTP::Request');

my $ua  = LWP::UserAgent->new;
my $req = HTTP::Request->new(TRACE => "http://www.apache.org/");
$req->protocol("HTTP/1.0");
my $res = $ua->simple_request($req);
like($res->content, qr/HTTP\/1.0/, '$res->content =~ /HTTP\/1.0/') or 
    $res->dump(prefix => "# ");
