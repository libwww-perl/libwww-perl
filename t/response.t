#!perl -w

# Test extra HTTP::Response methods.  Basic operation is tested in the
# message.t test suite.

use strict;
use Test;
plan tests => 23;

use HTTP::Date;
use HTTP::Request;
use HTTP::Response;

my $time = time;

my $req = HTTP::Request->new(GET => 'http://www.sn.no');
$req->date($time - 30);

my $r = new HTTP::Response 200, "OK";
$r->client_date($time - 20);
$r->date($time - 25);
$r->last_modified($time - 5000000);
$r->request($req);

#print $r->as_string;

my $current_age = $r->current_age;

ok($current_age >= 35  && $current_age <= 40);

my $freshness_lifetime = $r->freshness_lifetime;
ok($freshness_lifetime >= 12 * 3600);
ok($r->freshness_lifetime(heuristic_expiry => 0), undef);

my $is_fresh = $r->is_fresh;
ok($is_fresh);
ok($r->is_fresh(heuristic_expiry => 0), undef);

print "# current_age        = $current_age\n";
print "# freshness_lifetime = $freshness_lifetime\n";
print "# response is ";
print " not " unless $is_fresh;
print "fresh\n";

print "# it will be fresh for ";
print $freshness_lifetime - $current_age;
print " more seconds\n";

# OK, now we add an Expires header
$r->expires($time);
print "\n", $r->dump(prefix => "# ");

$freshness_lifetime = $r->freshness_lifetime;
ok($freshness_lifetime, 25);
$r->remove_header('expires');

# Now we try the 'Age' header and the Cache-Contol:
$r->header('Age', 300);
$r->push_header('Cache-Control', 'junk');
$r->push_header(Cache_Control => 'max-age = 10');

#print $r->as_string;

$current_age = $r->current_age;
$freshness_lifetime = $r->freshness_lifetime;

print "# current_age        = $current_age\n";
print "# freshness_lifetime = $freshness_lifetime\n";

ok($current_age >= 300);
ok($freshness_lifetime, 10);

ok($r->fresh_until);  # should return something
ok($r->fresh_until(heuristic_expiry => 0));  # should return something

my $r2 = HTTP::Response->parse($r->as_string);
my @h = $r2->header('Cache-Control');
ok(@h, 2);

$r->remove_header("Cache-Control");

ok($r->fresh_until);  # should still return something
ok($r->fresh_until(heuristic_expiry => 0), undef);

ok($r->redirects, 0);
$r->previous($r2);
ok($r->previous, $r2);
ok($r->redirects, 1);

$r2->previous($r->clone);
ok($r->redirects, 2);
for ($r->redirects) {
    ok($_->is_success);
}

ok($r->base, $r->request->uri);
$r->push_header("Content-Location", "/1/A/a");
ok($r->base, "http://www.sn.no/1/A/a");
$r->push_header("Content-Base", "/2/;a=/foo/bar");
ok($r->base, "http://www.sn.no/2/;a=/foo/bar");
$r->push_header("Content-Base", "/3/");
ok($r->base, "http://www.sn.no/2/;a=/foo/bar");
