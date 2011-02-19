#!perl -w

use strict;
use Test qw(plan ok skip);

plan tests => 125;

require HTTP::Message;
use Config qw(%Config);

my($m, $m2, @parts);

$m = HTTP::Message->new;
ok($m);
ok(ref($m), "HTTP::Message");
ok(ref($m->headers), "HTTP::Headers");
ok($m->as_string, "\n");
ok($m->headers->as_string, "");
ok($m->headers_as_string, "");
ok($m->content, "");

$m->header("Foo", 1);
ok($m->as_string, "Foo: 1\n\n");

$m2 = HTTP::Message->new($m->headers);
$m2->header(bar => 2);
ok($m->as_string, "Foo: 1\n\n");
ok($m2->as_string, "Bar: 2\nFoo: 1\n\n");
ok($m2->dump, "Bar: 2\nFoo: 1\n\n(no content)\n");

$m2 = HTTP::Message->new($m->headers, "foo");
ok($m2->as_string, "Foo: 1\n\nfoo\n");
ok($m2->as_string("<<\n"), "Foo: 1<<\n<<\nfoo");
$m2 = HTTP::Message->new($m->headers, "foo\n");
ok($m2->as_string, "Foo: 1\n\nfoo\n");

$m = HTTP::Message->new([a => 1, b => 2], "abc");
ok($m->as_string, "A: 1\nB: 2\n\nabc\n");

$m = HTTP::Message->parse("");
ok($m->as_string, "\n");
$m = HTTP::Message->parse("\n");
ok($m->as_string, "\n");
$m = HTTP::Message->parse("\n\n");
ok($m->as_string, "\n\n");
ok($m->content, "\n");

$m = HTTP::Message->parse("foo");
ok($m->as_string, "\nfoo\n");
$m = HTTP::Message->parse("foo: 1");
ok($m->as_string, "Foo: 1\n\n");
$m = HTTP::Message->parse("foo_bar: 1");
ok($m->as_string, "Foo_bar: 1\n\n");
$m = HTTP::Message->parse("foo: 1\n\nfoo");
ok($m->as_string, "Foo: 1\n\nfoo\n");
$m = HTTP::Message->parse(<<EOT);
FOO : 1
 2
  3
   4
bar:
 1
Baz: 1

foobarbaz
EOT
ok($m->as_string, <<EOT);
Bar: 
 1
Baz: 1
Foo: 1
 2
  3
   4

foobarbaz
EOT

$m = HTTP::Message->parse(<<EOT);
Date: Fri, 18 Feb 2005 18:33:46 GMT
Connection: close
Content-Type: text/plain

foo:bar
second line
EOT
ok($m->content(""), <<EOT);
foo:bar
second line
EOT
ok($m->as_string, <<EOT);
Connection: close
Date: Fri, 18 Feb 2005 18:33:46 GMT
Content-Type: text/plain

EOT

$m = HTTP::Message->parse("  abc\nfoo: 1\n");
ok($m->as_string, "\n  abc\nfoo: 1\n");
$m = HTTP::Message->parse(" foo : 1\n");
ok($m->as_string, "\n foo : 1\n");
$m = HTTP::Message->parse("\nfoo: bar\n");
ok($m->as_string, "\nfoo: bar\n");

$m = HTTP::Message->new([a => 1, b => 2], "abc");
ok($m->content("foo\n"), "abc");
ok($m->content, "foo\n");

$m->add_content("bar");
ok($m->content, "foo\nbar");
$m->add_content(\"\n");
ok($m->content, "foo\nbar\n");

ok(ref($m->content_ref), "SCALAR");
ok(${$m->content_ref}, "foo\nbar\n");
${$m->content_ref} =~ s/[ao]/i/g;
ok($m->content, "fii\nbir\n");

$m->clear;
ok($m->headers->header_field_names, 0);
ok($m->content, "");

ok($m->parts, undef);
$m->parts(HTTP::Message->new,
	  HTTP::Message->new([a => 1], "foo"),
	  HTTP::Message->new(undef, "bar\n"),
         );
ok($m->parts->as_string, "\n");

my $str = $m->as_string;
$str =~ s/\r/<CR>/g;
ok($str, <<EOT);
Content-Type: multipart/mixed; boundary=xYzZY

--xYzZY<CR>
<CR>
<CR>
--xYzZY<CR>
A: 1<CR>
<CR>
foo<CR>
--xYzZY<CR>
<CR>
bar
<CR>
--xYzZY--<CR>
EOT

$m2 = HTTP::Message->new;
$m2->parts($m);

$str = $m2->as_string;
$str =~ s/\r/<CR>/g;
ok($str =~ /boundary=(\S+)/);


ok($str, <<EOT);
Content-Type: multipart/mixed; boundary=$1

--$1<CR>
Content-Type: multipart/mixed; boundary=xYzZY<CR>
<CR>
--xYzZY<CR>
<CR>
<CR>
--xYzZY<CR>
A: 1<CR>
<CR>
foo<CR>
--xYzZY<CR>
<CR>
bar
<CR>
--xYzZY--<CR>
<CR>
--$1--<CR>
EOT

@parts = $m2->parts;
ok(@parts, 1);

@parts = $parts[0]->parts;
ok(@parts, 3);
ok($parts[1]->header("A"), 1);

$m2->parts([HTTP::Message->new]);
@parts = $m2->parts;
ok(@parts, 1);

$m2->parts([]);
@parts = $m2->parts;
ok(@parts, 0);

$m->clear;
$m2->clear;

$m = HTTP::Message->new([content_type => "message/http; boundary=aaa",
                        ],
                        <<EOT);
GET / HTTP/1.1
Host: www.example.com:8008

EOT

@parts = $m->parts;
ok(@parts, 1);
$m2 = $parts[0];
ok(ref($m2), "HTTP::Request");
ok($m2->method, "GET");
ok($m2->uri, "/");
ok($m2->protocol, "HTTP/1.1");
ok($m2->header("Host"), "www.example.com:8008");
ok($m2->content, "");

$m->content(<<EOT);
HTTP/1.0 200 OK
Content-Type: text/plain

Hello
EOT

$m2 = $m->parts;
ok(ref($m2), "HTTP::Response");
ok($m2->protocol, "HTTP/1.0");
ok($m2->code, "200");
ok($m2->message, "OK");
ok($m2->content_type, "text/plain");
ok($m2->content, "Hello\n");

eval { $m->parts(HTTP::Message->new, HTTP::Message->new) };
ok($@);

$m->add_part(HTTP::Message->new([a=>[1..3]], "a"));
$str = $m->as_string;
$str =~ s/\r/<CR>/g;
ok($str, <<EOT);
Content-Type: multipart/mixed; boundary=xYzZY

--xYzZY<CR>
Content-Type: message/http; boundary=aaa<CR>
<CR>
HTTP/1.0 200 OK
Content-Type: text/plain

Hello
<CR>
--xYzZY<CR>
A: 1<CR>
A: 2<CR>
A: 3<CR>
<CR>
a<CR>
--xYzZY--<CR>
EOT

$m->add_part(HTTP::Message->new([b=>[1..3]], "b"));

$str = $m->as_string;
$str =~ s/\r/<CR>/g;
ok($str, <<EOT);
Content-Type: multipart/mixed; boundary=xYzZY

--xYzZY<CR>
Content-Type: message/http; boundary=aaa<CR>
<CR>
HTTP/1.0 200 OK
Content-Type: text/plain

Hello
<CR>
--xYzZY<CR>
A: 1<CR>
A: 2<CR>
A: 3<CR>
<CR>
a<CR>
--xYzZY<CR>
B: 1<CR>
B: 2<CR>
B: 3<CR>
<CR>
b<CR>
--xYzZY--<CR>
EOT

$m = HTTP::Message->new;
$m->add_part(HTTP::Message->new([a=>[1..3]], "a"));
ok($m->header("Content-Type"), "multipart/mixed; boundary=xYzZY");
$str = $m->as_string;
$str =~ s/\r/<CR>/g;
ok($str, <<EOT);
Content-Type: multipart/mixed; boundary=xYzZY

--xYzZY<CR>
A: 1<CR>
A: 2<CR>
A: 3<CR>
<CR>
a<CR>
--xYzZY--<CR>
EOT

$m = HTTP::Message->new;
$m->content_ref(\my $foo);
ok($m->content_ref, \$foo);
$foo = "foo";
ok($m->content, "foo");
$m->add_content("bar");
ok($foo, "foobar");
ok($m->as_string, "\nfoobar\n");
$m->content_type("message/foo");
$m->parts(HTTP::Message->new(["h", "v"], "C"));
ok($foo, "H: v\r\n\r\nC");
$foo =~ s/C/c/;
$m2 = $m->parts;
ok($m2->content, "c");

$m = HTTP::Message->new;
$foo = [];
$m->content($foo);
ok($m->content, $foo);
ok(${$m->content_ref}, $foo);
ok(${$m->content_ref([])}, $foo);
ok($m->content_ref != $foo);
eval {$m->add_content("x")};
ok($@ && $@ =~ /^Can't append to ARRAY content/);

$foo = sub { "foo" };
$m->content($foo);
ok($m->content, $foo);
ok(${$m->content_ref}, $foo);

$m->content_ref($foo);
ok($m->content, $foo);
ok($m->content_ref, $foo);

eval {$m->content_ref("foo")};
ok($@ && $@ =~ /^Setting content_ref to a non-ref/);

$m->content_ref(\"foo");
eval {$m->content("bar")};
ok($@ && $@ =~ /^Modification of a read-only value/);

$foo = "foo";
$m->content_ref(\$foo);
ok($m->content("bar"), "foo");
ok($foo, "bar");
ok($m->content, "bar");
ok($m->content_ref, \$foo);

$m = HTTP::Message->new;
$m->content("fo=6F");
ok($m->decoded_content, "fo=6F");
$m->header("Content-Encoding", "quoted-printable");
ok($m->decoded_content, "foo");

$m = HTTP::Message->new;
$m->header("Content-Encoding", "gzip, base64");
$m->content_type("text/plain; charset=UTF-8");
$m->content("H4sICFWAq0ECA3h4eAB7v3u/R6ZCSUZqUarCoxm7uAAZKHXiEAAAAA==\n");

$@ = "";
ok(sub { eval { $m->decoded_content } }, "\x{FEFF}Hi there \x{263A}\n");
ok($@ || "", "");
ok($m->content, "H4sICFWAq0ECA3h4eAB7v3u/R6ZCSUZqUarCoxm7uAAZKHXiEAAAAA==\n");

$m2 = $m->clone;
ok($m2->decode);
ok($m2->header("Content-Encoding"), undef);
ok($m2->content, qr/Hi there/);

ok(grep { $_ eq "gzip" } $m->decodable);

my $tmp = MIME::Base64::decode($m->content);
$m->content($tmp);
$m->header("Content-Encoding", "gzip");
$@ = "";
ok(sub { eval { $m->decoded_content } }, "\x{FEFF}Hi there \x{263A}\n");
ok($@ || "", "");
ok($m->content, $tmp);

$m->remove_header("Content-Encoding");
$m->content("a\xFF");

ok(sub { $m->decoded_content }, "a\x{FFFD}");
ok(sub { $m->decoded_content(charset_strict => 1) }, undef);

$m->header("Content-Encoding", "foobar");
ok($m->decoded_content, undef);
ok($@ =~ /^Don't know how to decode Content-Encoding 'foobar'/);

my $err = 0;
eval {
    $m->decoded_content(raise_error => 1);
    $err++;
};
ok($@ =~ /Don't know how to decode Content-Encoding 'foobar'/);
ok($err, 0);

eval {
    HTTP::Message->new([], "\x{263A}");
};
ok($@ =~ /bytes/);
$m = HTTP::Message->new;
eval {
    $m->add_content("\x{263A}");
};
ok($@ =~ /bytes/);
eval {
    $m->content("\x{263A}");
};
ok($@ =~ /bytes/);

# test the add_content_utf8 method
$m = HTTP::Message->new(["Content-Type", "text/plain; charset=UTF-8"]);
$m->add_content_utf8("\x{263A}");
$m->add_content_utf8("-\xC5");
ok($m->content, "\xE2\x98\xBA-\xC3\x85");
ok($m->decoded_content, "\x{263A}-\x{00C5}");

$m = HTTP::Message->new([
    "Content-Type", "text/plain",
    ],
    "Hello world!"
);
$m->content_length(length $m->content);
$m->encode("deflate");
$m->dump(prefix => "# ");
ok($m->dump(prefix => "| "), <<'EOT');
| Content-Encoding: deflate
| Content-Type: text/plain
| 
| x\x9C\xF3H\xCD\xC9\xC9W(\xCF/\xCAIQ\4\0\35\t\4^
EOT
$m->encode("base64", "identity");
ok($m->as_string, <<'EOT');
Content-Encoding: deflate, base64, identity
Content-Type: text/plain

eJzzSM3JyVcozy/KSVEEAB0JBF4=
EOT
ok($m->decoded_content, "Hello world!");

# Raw RFC 1951 deflate
$m = HTTP::Message->new([
    "Content-Type" => "text/plain",
    "Content-Encoding" => "deflate, base64",
    ],
    "80jNyclXCM8vyklRBAA="
    );
ok($m->decoded_content, "Hello World!");
ok(!$m->header("Client-Warning"));


if (eval "require IO::Uncompress::Bunzip2") {
    $m = HTTP::Message->new([
        "Content-Type" => "text/plain",
        "Content-Encoding" => "x-bzip2, base64",
        ],
	"QlpoOTFBWSZTWcvLx0QAAAHVgAAQYAAAQAYEkIAgADEAMCBoYlnQeSEMvxdyRThQkMvLx0Q=\n"
    );
    ok($m->decoded_content, "Hello world!\n");
    ok($m->decode);
    ok($m->content, "Hello world!\n");

    if (eval "require IO::Compress::Bzip2") {
	$m = HTTP::Message->new([
	    "Content-Type" => "text/plain",
	    ],
	    "Hello world!"
	);
	ok($m->encode("x-bzip2"));
	ok($m->header("Content-Encoding"), "x-bzip2");
	ok($m->content =~ /^BZh.*\0/);
	ok($m->decoded_content, "Hello world!");
	ok($m->decode);
	ok($m->content, "Hello world!");
    }
    else {
	skip("Need IO::Compress::Bzip2", undef) for 1..6;
    }
}
else {
    skip("Need IO::Uncompress::Bunzip2", undef) for 1..9;
}

# test decoding of XML content
$m = HTTP::Message->new(["Content-Type", "application/xml"], "\xFF\xFE<\0?\0x\0m\0l\0 \0v\0e\0r\0s\0i\0o\0n\0=\0\"\x001\0.\x000\0\"\0 \0e\0n\0c\0o\0d\0i\0n\0g\0=\0\"\0U\0T\0F\0-\x001\x006\0l\0e\0\"\0?\0>\0\n\0<\0r\0o\0o\0t\0>\0\xC9\0r\0i\0c\0<\0/\0r\0o\0o\0t\0>\0\n\0");
ok($m->decoded_content, "<?xml version=\"1.0\"?>\n<root>\xC9ric</root>\n");
