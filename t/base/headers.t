require HTTP::Headers;

print "1..8\n";

$h = new HTTP::Headers
	"mime-version" => "1.0",
	"content-type" => "text/html";

$h->header(URI => "http://www.oslonett.no/");

if ($h->header("MIME-Version") eq "1.0") {	
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

if ($h->header('Uri') =~ /^http:/) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}


$h->header("MY-header" => "foo",
	   "Date" => "somedate",
	   "Accept" => ["text/plain", "image/*"],
	  );
$h->pushHeader("accept" => "audio/basic");

if ($h->header("date") eq "somedate") {
     print "ok 3\n";
}

@accept = $h->header("accept");
if (@accept == 3) {
    print "ok 4\n";
}

$h->removeHeader("uri", "date");


$str = $h->asString;
print "\nHeader looks like this now:\n$str\n";

$lines = ($str =~ tr/\n/\n/);

if ($lines == 6) {
    print "ok 5\n";
} else {
    print "Header has $lines lines\n";
    print "not ok 5\n";
}

$h2 = $h->clone;

$h->header("accept", "*/*");
$h->removeHeader("my-header");

@accept = $h2->header("accept");
if (@accept == 3) {
    print "ok 6\n";
}

@accept = $h->header("accept");
if (@accept == 1) {
    print "ok 7\n";
}

@x = ();
$h2->scan(sub {push(@x, shift);});

$str = join(";", @x);
$expected = "MIME-Version;Accept;Accept;Accept;Content-Type;MY-Header";

if ($str eq $expected) {
    print "ok 8\n";
} else {
    print "Headers are '$str',\nexpected    '$expected'\n";
    print "not ok 8\n";
}
