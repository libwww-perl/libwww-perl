print "1..3\n";

use URI::URL;

# We used to have problems with URLs that used a base that was
# not absolute itself.

$u1 = url("/foo/bar", "http://www.acme.com/");
$u2 = url("../foo/", $u1);
$u3 = url("zoo/foo", $u2);

$a1 = $u1->abs->as_string;
$a2 = $u2->abs->as_string;
$a3 = $u3->abs->as_string;

print "$a1\n$a2\n$a3\n";

print "not " unless $a1 eq "http://www.acme.com/foo/bar";
print "ok 1\n";
print "not " unless $a2 eq "http://www.acme.com/foo/";
print "ok 2\n";
print "not " unless $a3 eq "http://www.acme.com/foo/zoo/foo";
print "ok 3\n";

