print "1..1\n";

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/ChunkedScript");
my $res = $ua->request($req);

print $res->as_string;

# This did not really work
print "not " unless $res->code == 404;
print "ok 1\n";
