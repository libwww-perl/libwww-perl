use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('jigsaw.w3.org' => 80);

use HTTP::Request;
use LWP::UserAgent;

plan tests => 8;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/ChunkedScript");
my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'request: Got a proper response');

ok($res->is_success, 'response success');
is($res->content_type, 'text/plain', 'Content-Type: text/plain');
is($res->header('Client-Transfer-Encoding'), "chunked", 'Client-Transfer-Encoding: chunked');

for my $cref ( ${$res->content_ref} ) {
    $cref =~ s/\015?\012/\n/g;
    like($cref, qr/Below this line, is 1000 repeated lines of 0-9/, 'proper text found');
    $cref =~ s/^.*?-----+\n//s;

    my @lines = split(/^/, $cref);
    is(scalar(@lines), 1000, 'Got 1000 lines');

    # check that all lines are the same
    my $first = shift(@lines);
    like($first, qr/^\d+$/, 'The first line is a number');

    is(scalar(grep {$_ ne $first} @lines), 0, 'All lines are the same');
}
