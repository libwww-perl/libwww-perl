#!/usr/bin/perl

use strict;
use Getopt::Long;
use File::Listing;
use LWP::Simple;

my $force;
my $ok = 1;
if (!GetOptions("f" => \$force)) {
    die "usage";
}

if (!$force) {
    print "1..0 # run this test with -f and a running internet connection\n";
    exit 0;
}

# some sample URLs
my @urls = (
	    "http://rsd.gsfc.nasa.gov/goesg/earth/Weather/GMS-5/jpg/vis/4km/",
	    "http://www.apache.org/~jon/scarab/nightly/",
	    "http://www.apache.org/dist/apr/?C=N&O=D",
	    "http://xml.apache.org/dist/batik/",
	    "http://gump.covalent.net/jars/?C=N&O=D",
	    "http://perl.apache.org/rpm/distrib/",
	    "http://stein.cshl.org/WWW/software/",
	    "http://www.cpan.org/modules/by-module/",
	   );
print "1.." . scalar(@urls) . "\n";

for my $url (@urls) {
    my @listing = parse_dir(get($url),undef,"apache");
    print "not " if @listing == 0;
    print "ok " . $ok++ . "\n";
    #require Data::Dumper; print Data::Dumper->Dump(["Listing for $url", \@listing],[]);
}
