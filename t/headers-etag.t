#!perl -w

use strict;
use Test;

plan tests => 4;

require HTTP::Headers::ETag;

my $h = HTTP::Headers->new;

$h->etag("tag1");
ok($h->etag, qq("tag1"));

$h->etag("w/tag2");
ok($h->etag, qq(W/"tag2"));

$h->if_match(qq(W/"foo", bar, baz), "bar");
$h->if_none_match(333);

$h->if_range("tag3");
ok($h->if_range, qq("tag3"));

my $t = time;
$h->if_range($t);
ok($h->if_range, $t);

print $h->as_string;

