print "1..1\n";

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/TE/foo.txt");
$req->header("TE", "deflate");
#$req->header(TE => "chunked");
#$req->header("TE", "gzip");

my $res = $ua->request($req);

my $c = $res->content;
$res->content("");

print $res->as_string;

require Data::Dump;
print Data::Dump::dump($c), "\n";

print "not " unless $res->is_success;
print "ok 1\n";

$req->header("TE", "gzip");
#$req->remove_header("TE");
$res = $ua->request($req);
$res->content("");

print $res->as_string;


