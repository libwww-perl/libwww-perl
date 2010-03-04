#!perl -w

use strict;
use Test;

plan tests => 14;

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

my $res = $ua->get("data:text/html,%3Chtml%3E%3Chead%3E%3Cmeta%20http-equiv%3D%22Content-Script-Type%22%20content%3D%22text%2Fjavascript%22%3E%3Cmeta%20http-equiv%3D%22Content-Style-Type%22%20content%3D%22text%2Fcss%22%3E%3C%2Fhead%3E%3C%2Fhtml%3E");
ok($res->header("Content-Style-Type", "text/css"));
ok($res->header("Content-Script-Type", "text/javascript"));
