#!/usr/local/bin/perl -w
#
# Test retrieving a file with a 'file://' URL,
# and saving into a file
#

use lib '..';

use LWP::Simple;
require LWP::Protocol::file;

$me = 'getAndStore file://';    # test name for reporting

# To test this we need a file that exists.
# We could use `pwd` . 'getAndPrint-local.pl :-)'

my $orig = '/etc/motd';         # local file 
my $copy = "/usr/tmp/lwp-test-$$"; # downloaded copy

# do the retrieval
getstore("file://localhost$orig", $copy);

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
