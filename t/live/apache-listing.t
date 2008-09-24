#!perl -w

use Test;

use strict;
use File::Listing;
use LWP::Simple;

# some sample URLs
my @urls = (
	    "http://www.apache.org/dist/apr/?C=N&O=D",
	    "http://perl.apache.org/rpm/distrib/",
	    "http://stein.cshl.org/WWW/software/",
	    "http://www.cpan.org/modules/by-module/",
	   );
plan tests => scalar(@urls);

for my $url (@urls) {
    print "# $url\n";
    my @listing = parse_dir(get($url),undef,"apache");
    ok(@listing);
}
