#!perl -w

use Test;

use strict;
use File::Listing;
use LWP::Simple;

# some sample URLs
my @urls = (
	    "http://www.apache.org/dist/apr/?C=N&O=D",
	    "http://perl.apache.org/rpm/distrib/",
	    "http://www.cpan.org/modules/by-module/",
	   );
plan tests => scalar(@urls);

for my $url (@urls) {
    print "# $url\n";
    my $dir = get($url);
    unless ($dir) {
	print "# Can't get document at $url\n";
	ok(0);
	next;
    }
    my @listing = parse_dir($dir, undef, "apache");
    ok(@listing);
}
