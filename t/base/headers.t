use strict;

require HTTP::Headers;

print "1..17\n";

my $h = new HTTP::Headers
	mime_version  => "1.0",
	content_type  => "text/html";

$h->header(URI => "http://www.oslonett.no/");

if ($h->header("MIME-Version") eq "1.0") {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}

if ($h->header('Uri') =~ /^http:/) {
    print "ok 2\n";
}
else {
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

my @accept = $h->header("accept");
if (@accept == 3) {
    print "ok 4\n";
}

$h->remove_header("uri", "date");


my $str = $h->as_string;
print "\nHeader looks like this now:\n$str\n";

my $lines = ($str =~ tr/\n/\n/);

if ($lines == 6) {
    print "ok 5\n";
}
else {
    print "Header has $lines lines\n";
    print "not ok 5\n";
}

my $h2 = $h->clone;

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

my @x = ();
$h2->scan(sub {push(@x, shift);});

$str = join(";", @x);
my $expected = "Connection;Accept;Accept;Accept;Content-Type;MY-Header";

if ($str eq $expected) {
    print "ok 8\n";
}
else {
    print "Headers are '$str',\nexpected    '$expected'\n";
    print "not ok 8\n";
}

# Check headers with embedded newlines:

$h = new HTTP::Headers
	a => "foo\n\n",
	b => "foo\nbar",
	c => "foo\n\nbar\n\n",
	d => "foo\n\tbar";
$str = $h->as_string("<<\n");
print "-----\n$str------\n";

print "not " unless $str =~ /^A:\s*foo<<\n
                              B:\s*foo<<\n
	                        \s+bar<<\n
                              C:\s*foo<<\n
                                \s+bar<<\n
	                      D:\s*foo<<\n
                                \t bar<<\n
                             $/x;
print "ok 9\n";


# Check with FALSE $HTML::Headers::TRANSLATE_UNDERSCORE
{
local($HTTP::Headers::TRANSLATE_UNDERSCORE);
$HTTP::Headers::TRANSLATE_UNDERSCORE = undef;  # avoid -w warning

$h = HTTP::Headers->new;

$h->header(abc_abc   => "foo");
$h->header("abc-abc" => "bar");

#print $h->as_string;

print "not " unless $h->header("ABC_ABC") eq "foo" &&
                    $h->header("ABC-ABC") eq "bar";
print "ok 10\n";

print "not " unless $h->remove_header("Abc_Abc") &&
                    !defined($h->header("abc_abc")) &&
                    $h->header("ABC-ABC") eq "bar";
print "ok 11\n";
}

# Check if objects as header values works
require URI;
$h->header(URI => URI->new("http://www.perl.org"));

print "not " unless $h->header("URI")->scheme eq "http";
print "ok 12\n";

#$h->push_header("URI", "http://www.perl.com");

print "not " unless $h->header("URI");
print "ok 13\n";

$h->clear;
print "not " unless $h->as_string eq "";
print "ok 14\n";

$h->content_type("text/plain");
$h->header(content_md5 => "dummy");
$h->header("Content-Foo" => "foo");
$h->header(Location => "http:", xyzzy => "plugh!");

#print $h->as_string;
print "not " unless $h->as_string eq <<EOT; print "ok 15\n";
Location: http:
Content-MD5: dummy
Content-Type: text/plain
Content-Foo: foo
Xyzzy: plugh!
EOT

my $c = $h->remove_content_headers;
print "not " unless $h->as_string eq <<EOT; print "ok 16\n";
Location: http:
Xyzzy: plugh!
EOT

print "not " unless $c->as_string eq <<EOT; print "ok 17\n";
Content-MD5: dummy
Content-Type: text/plain
Content-Foo: foo
EOT
