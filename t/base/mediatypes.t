use LWP::MediaTypes;

@tests =
(
 ["/this.dir/file.html" => "text/html",],
 ["test.gif.htm"        => "text/html",],
 #["test.txt.gz"         => "text/plain",],
);

$notests = @tests;
print "1..$notests\n";

$testno = 1;
for (@tests) {
    ($file, $expectedtype) = @$_;
    $type = guessMediaType($file);
    $type = "undef" unless defined $type;
    if ($type eq $expectedtype) {
	print "ok $testno\n";
    } else {
	print "expected $expectedtype for $file, got $type\n";
	print "nok ok $testno\n";
    }
    $testno++;
}

