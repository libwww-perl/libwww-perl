#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 19;

require HTTP::Headers;

my $h = new HTTP::Headers
	mime_version  => "1.0",
	content_type  => "text/html";
$h->header(URI => "http://www.oslonett.no/");

ok($h->header("MIME-Version"), "1.0");
ok($h->header('Uri'), "http://www.oslonett.no/");

$h->header("MY-header" => "foo",
	   "Date" => "somedate",
	   "Accept" => ["text/plain", "image/*"],
	  );
$h->push_header("accept" => "audio/basic");

ok($h->header("date"), "somedate");

my @accept = $h->header("accept");
ok(@accept, 3);

$h->remove_header("uri", "date");

my $str = $h->as_string;
my $lines = ($str =~ tr/\n/\n/);
ok($lines, 6);

my $h2 = $h->clone;

$h->header("accept", "*/*");
$h->remove_header("my-header");

@accept = $h2->header("accept");
ok(@accept, 3);

@accept = $h->header("accept");
ok(@accept, 1);

# Check order of headers, but first remove this one
$h2->remove_header('mime_version');

# and add this general header
$h2->header(Connection => 'close');

my @x = ();
$h2->scan(sub {push(@x, shift);});
ok(join(";", @x), "Connection;Accept;Accept;Accept;Content-Type;MY-Header");

# Check headers with embedded newlines:
$h = HTTP::Headers->new(
	a => "foo\n\n",
	b => "foo\nbar",
	c => "foo\n\nbar\n\n",
	d => "foo\n\tbar",
	e => "foo\n  bar  ",
	f => "foo\n bar\n  baz\nbaz",
     );
ok($h->as_string("<<\n"), <<EOT);
A: foo<<
B: foo<<
 bar<<
C: foo<<
 bar<<
D: foo<<
\tbar<<
E: foo<<
  bar<<
F: foo<<
 bar<<
  baz<<
 baz<<
EOT


# Check with FALSE $HTML::Headers::TRANSLATE_UNDERSCORE
{
    local($HTTP::Headers::TRANSLATE_UNDERSCORE);
    $HTTP::Headers::TRANSLATE_UNDERSCORE = undef; # avoid -w warning

    $h = HTTP::Headers->new;
    $h->header(abc_abc   => "foo");
    $h->header("abc-abc" => "bar");

    ok($h->header("ABC_ABC"), "foo");
    ok($h->header("ABC-ABC"),"bar");
    ok($h->remove_header("Abc_Abc"));
    ok(!defined($h->header("abc_abc")));
    ok($h->header("ABC-ABC"), "bar");
}

# Check if objects as header values works
require URI;
$h->header(URI => URI->new("http://www.perl.org"));

ok($h->header("URI")->scheme, "http");

$h->clear;
ok($h->as_string, "");

$h->content_type("text/plain");
$h->header(content_md5 => "dummy");
$h->header("Content-Foo" => "foo");
$h->header(Location => "http:", xyzzy => "plugh!");

ok($h->as_string, <<EOT);
Location: http:
Content-MD5: dummy
Content-Type: text/plain
Content-Foo: foo
Xyzzy: plugh!
EOT

my $c = $h->remove_content_headers;
ok($h->as_string, <<EOT);
Location: http:
Xyzzy: plugh!
EOT

ok($c->as_string, <<EOT);
Content-MD5: dummy
Content-Type: text/plain
Content-Foo: foo
EOT
