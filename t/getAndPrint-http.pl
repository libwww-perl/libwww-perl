#!/usr/local/bin/perl -w
#
# Test retrieving a file with a 'http://' URL,
# and printing to STDOUT
#

use lib '..';

require LWP::Debug;
require LWP::http;
require LWP::UserAgent;

#LWP::Debug::level('+');

$me = 'getAndPrint http://';    # test name for reporting

my $ua = new LWP::UserAgent;    # create a useragent to test

# To test this we need a local file available
# remotely by HTTP. XXX ought to provide on-line test suite,
# possibly implemented as CGI scripts

my $url = 'http://web.nexor.co.uk/users/mak/cgi-bin/lwp-test.pl/simple-html';
my $copy = "/usr/tmp/lwp-test-$$"; # downloaded copy

# getAndPrint prints to STDOUT, so we save it to a file
open (OUT, ">$copy") or die "Cannot open $copy: $!";
select(OUT);

# do the retrieval
$ua->getAndPrint($url);

close(OUT);
select(STDOUT);

# read and compare the files
close(IN);
open(IN, $copy) or die "Cannot open '$copy': $!";
undef($/);
$copytext = <IN>;
close(IN);

$expected = <<EOM;
<HTML>
<HEAD>
<TITLE>
LWP Test Suite
</TITLE>
</HEAD>
<BODY>
<H1>LWP Test Suite</H1>
This is a simple text
</BODY>
</HTML>
EOM

if ($expected eq $copytext) {
    print "'$me' ok\n";
    unlink($copy);
}
else {
    die "'$me' failed: $copy differs from expected html";
}
