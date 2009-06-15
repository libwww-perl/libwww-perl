#!perl -w

use strict;
use Test;
plan tests => 21;

use HTTP::Response;
my $r = HTTP::Response->new(200, "OK");
ok($r->content_charset, undef);
ok($r->content_type_charset, undef);

$r->content_type("text/plain");
ok($r->content_charset, undef);

$r->content("abc");
ok($r->content_charset, "US-ASCII");

$r->content("f\xE5rep\xF8lse\n");
ok($r->content_charset, "ISO-8859-1");

$r->content("f\xC3\xA5rep\xC3\xB8lse\n");
ok($r->content_charset, "UTF-8");

$r->content_type("text/html");
$r->content(<<'EOT');
<meta charset="UTF-8">
EOT
ok($r->content_charset, "UTF-8");

$r->content(<<'EOT');
<body>
<META CharSet="Utf-16-LE">
<meta charset="ISO-8859-1">
EOT
ok($r->content_charset, "UTF-8");

$r->content(<<'EOT');
<!-- <meta charset="UTF-8">
EOT
ok($r->content_charset, "US-ASCII");

$r->content(<<'EOT');
<meta content="text/plain; charset=UTF-8">
EOT
ok($r->content_charset, "UTF-8");

$r->content_type('text/plain; charset="iso-8859-1"');
ok($r->content_charset, "ISO-8859-1");
ok($r->content_type_charset, "ISO-8859-1");

$r->content_type("application/xml");
$r->content("<foo>..</foo>");
ok($r->content_charset, "UTF-8");

require Encode;
for my $enc ("UTF-16-BE", "UTF-16-LE", "UTF-32-BE", "UTF-32-LE") {
    $r->content(Encode::encode($enc, "<foo>..</foo>"));
    ok($r->content_charset, $enc);
}

$r->content(<<'EOT');
<?xml version="1.0" encoding="utf8" ?>
EOT
ok($r->content_charset, "utf8");

$r->content(<<'EOT');
<?xml version="1.0" encoding=" "?>
EOT
ok($r->content_charset, "UTF-8");

$r->content(<<'EOT');
<?xml version="1.0" encoding="  ISO-8859-1 "?>
EOT
ok($r->content_charset, "ISO-8859-1");

$r->content(<<'EOT');
<?xml version="1.0"
encoding="US-ASCII" ?>
EOT
ok($r->content_charset, "US-ASCII");
