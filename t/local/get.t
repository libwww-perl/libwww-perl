#
# Test retrieving a file with a 'file://' URL,
#

print "1..2\n";

use LWP::Simple;
require LWP::Protocol::file;

my $orig = "/usr/tmp/lwp-orig-$$";          # local file
my $copy = "/usr/tmp/lwp-copy-$$"; 	    # downloaded copy

# First we create the original
open(OUT, ">$orig") or die "Cannot open $orig: $!";
for (1..100) {
    print OUT "This is line $_ of $orig\n";
}
close(OUT);


# Then we make a test using getprint(), so we need to capture stdout
open (OUT, ">$copy") or die "Cannot open $copy: $!";
select(OUT);

# do the retrieval
getprint("file://localhost$orig");

close(OUT);
select(STDOUT);

# read and compare the files
open(IN, $orig) or die "Cannot open '$orig': $!";
undef($/);
$origtext = <IN>;
close(IN);
open(IN, $copy) or die "Cannot open '$copy': $!";
undef($/);
$copytext = <IN>;
close(IN);

unlink($copy);

if ($origtext eq $copytext) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}


# Test getstore() function

getstore("file:$orig", $copy);

# Take a look at the new copy
open(IN, $copy) or die "Cannot open '$copy': $!";
undef($/);
$copytext = <IN>;
close(IN);

unlink($orig);
unlink($copy);

if ($origtext eq $copytext) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}
