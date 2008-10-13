#!perl -w

# Test extra HTTP::Response methods.  Basic operation is tested in the
# message.t test suite.

use strict;
use Test;
plan tests => 8;

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

my $is_fresh = $r->is_fresh;
ok($is_fresh);

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
print $r->dump(prefix => "# ");

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

my $r2 = HTTP::Response->parse($r->as_string);
my @h = $r2->header('Cache-Control');
ok(@h, 2);
