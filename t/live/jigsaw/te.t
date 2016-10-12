use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('jigsaw.w3.org' => 80);

use HTTP::Request;
use LWP::UserAgent;

plan tests => 9;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $content;
for my $te (undef, "", "deflate", "gzip", "trailers, deflate;q=0.4, identity;q=0.1") {
    my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/TE/foo.txt");

    if (defined $te) {
        $req->header(TE => $te);
        $req->header(Connection => "TE");
    }

    my $res = $ua->request($req);
    isa_ok($res, 'HTTP::Response', 'request: Got a proper response');
    if (defined $content) {
        is($res->content, $content, 'content: Correct content');
    }
    else {
        $content = $res->content;
    }
}
