require HTTP::Headers;

print "1..8\n";

$h = new HTTP::Headers
	mime_version  => "1.0",
	content_type  => "text/html";

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
$h->push_header("accept" => "audio/basic");

if ($h->header("date") eq "somedate") {
     print "ok 3\n";
}

@accept = $h->header("accept");
if (@accept == 3) {
    print "ok 4\n";
}

$h->remove_header("uri", "date");


$str = $h->as_string;
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
$h->remove_header("my-header");

@accept = $h2->header("accept");
if (@accept == 3) {
    print "ok 6\n";
}

@accept = $h->header("accept");
if (@accept == 1) {
    print "ok 7\n";
}

# Check order of headers, but first remove this one
$h2->remove_header('mime_version');

# and add this general header
$h2->header(Connection => 'close');

@x = ();
$h2->scan(sub {push(@x, shift);});

$str = join(";", @x);
$expected = "Connection;Accept;Accept;Accept;Content-Type;MY-Header";

if ($str eq $expected) {
    print "ok 8\n";
} else {
    print "Headers are '$str',\nexpected    '$expected'\n";
    print "not ok 8\n";
}
