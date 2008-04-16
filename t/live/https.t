#!perl -w

use strict;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();
my $res = $ua->simple_request(HTTP::Request->new(GET => "https://www.sun.com"));

if ($res->code == 501 && $res->message =~ /Protocol scheme 'https' is not supported/) {
    print "1..0 # Skipped: " . $res->message . "\n";
    exit;
}

print "1..2\n";
print "not " unless $res->is_success;
print "ok 1\n";

print "not " unless $res->content =~ /Sun Microsystems/;
print "ok 2\n";

my $cref = $res->content_ref;
substr($$cref, 100) = "..." if length($$cref) > 100;
print "\n", $res->as_string;
