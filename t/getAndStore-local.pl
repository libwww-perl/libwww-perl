#!/usr/local/bin/perl -w
#
# Test retrieving a file with a 'file://' URL,
# and saving into a file
#

sub BEGIN {    unshift(@INC, '../lib'); }

require LWP::file;
require LWP::UserAgent;

$me = 'getAndStore file://';    # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

# To test this we need a file that exists.
# We could use `pwd` . 'getAndPrint-local.pl :-)'

my $orig = '/etc/motd';         # local file 
my $copy = "/usr/tmp/lwp-test-$$"; # downloaded copy

# do the retrieval
$ua->getAndStore("file://localhost$orig", $copy);

# read and compare the files
open(IN, $orig) or die "Cannot open '$orig': $!";
undef($/);
$origtext = <IN>;
close(IN);
open(IN, $copy) or die "Cannot open '$copy': $!";
undef($/);
$copytext = <IN>;
close(IN);

if ($origtext eq $copytext) {
    print "'$me' ok\n";
    unlink($copy);
}
else {
    die "'$me' failed: $copy differs from $orig";
}
