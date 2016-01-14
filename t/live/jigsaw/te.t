use strict;
use warnings;
use Test::More;

use HTTP::Request;
use LWP::UserAgent;

plan tests => 15;

my $ua = LWP::UserAgent->new(keep_alive => 1);
isa_ok($ua, 'LWP::UserAgent', 'new: UserAgent instance');

my $content;
for my $te (undef, "", "deflate", "gzip", "trailers, deflate;q=0.4, identity;q=0.1") {
    my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/TE/foo.txt");
    isa_ok($req, 'HTTP::Request', 'new: HTTP::Request instance');

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
