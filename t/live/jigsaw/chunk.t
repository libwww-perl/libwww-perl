# perl

use strict;
use warnings;
use Test::More;
plan tests => 8;

use_ok('LWP::UserAgent');
use_ok('HTTP::Request');

my $url = "http://jigsaw.w3.org/HTTP/ChunkedScript";
my $ua  = LWP::UserAgent->new(keep_alive => 1);
my $req = HTTP::Request->new(GET => $url);
my $res = $ua->request($req);

ok($res->is_success, "\$res->is_success [$url]");
is($res->content_type, "text/plain", '$res->content_type');
is($res->header("Client-Transfer-Encoding"), "chunked", '$res->header("Client-Transfer-Encoding")');

for (${$res->content_ref}) {
    s/\015?\012/\n/g;
    /Below this line, is 1000 repeated lines of 0-9/ || die;
    s/^.*?-----+\n//s;

    my @lines = split(/^/);
    is(scalar(@lines), 1000, "Number of lines [1000]");

    # check that all lines are the same
    my $first = shift(@lines);
    my $no_they_are_not;
    for (@lines) {
        $no_they_are_not++ if $_ ne $first;
    }
    ok(! $no_they_are_not, "lines match");
    like($first, qr/^\d+$/, "line matches");
}
