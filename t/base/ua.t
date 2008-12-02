#!perl -w

use strict;
use Test;

plan tests => 12;

use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
my $clone = $ua->clone;

ok($ua->agent =~ /^libwww-perl/);
ok(!defined $ua->proxy(ftp => "http://www.sol.no"));
ok($ua->proxy("ftp"), "http://www.sol.no");

my @a = $ua->proxy([qw(ftp http wais)], "http://proxy.foo.com");
for (@a) { $_ = "undef" unless defined; }

ok("@a", "http://www.sol.no undef undef");
ok($ua->proxy("http"), "http://proxy.foo.com");
ok(ref($ua->default_headers), "HTTP::Headers");

$ua->default_header("Foo" => "bar", "Multi" => [1, 2]);
ok($ua->default_headers->header("Foo"), "bar");
ok($ua->default_header("Foo"), "bar");

# Try it
$ua->proxy(http => "loopback:");
$ua->agent("foo/0.1");

ok($ua->get("http://www.example.com", x => "y")->content, <<EOT);
GET http://www.example.com
User-Agent: foo/0.1
Foo: bar
Multi: 1
Multi: 2
X: y

EOT

ok(ref($clone->{proxy}), 'HASH');

ok($ua->proxy(http => undef), "loopback:");
ok($ua->proxy('http'), undef);
