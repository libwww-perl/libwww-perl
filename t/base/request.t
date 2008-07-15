# Test extra HTTP::Request methods.  Basic operation is tested in the
# message.t test suite.

use strict;

use Test;
plan tests => 7;

use HTTP::Request;

my $req = HTTP::Request->new(GET => "http://www.example.com");
$req->accept_decodable;

ok($req->method, "GET");
ok($req->uri, "http://www.example.com");
ok($req->header("Accept-Encoding") =~ /\bgzip\b/);  # assuming Compress::Zlib is there

($_ = $req->as_string) =~ s/^/# /gm;
print;

ok($req->method("DELETE"), "GET");
ok($req->method, "DELETE");

ok($req->uri("http:"), "http://www.example.com");
ok($req->uri, "http:");

