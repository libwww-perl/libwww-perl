#!perl -w

use strict;
use Test;

plan tests => 6;

use HTTP::Response;
use HTTP::Headers::Auth;

my $res = HTTP::Response->new(401);
$res->push_header(WWW_Authenticate => qq(Foo realm="WallyWorld", foo=bar, Bar realm="WallyWorld2"));
$res->push_header(WWW_Authenticate => qq(Basic Realm="WallyWorld", foo=bar, bar=baz));

print $res->as_string;

my %auth = $res->www_authenticate;

ok(keys(%auth), 3);

ok($auth{basic}{realm}, "WallyWorld");
ok($auth{bar}{realm}, "WallyWorld2");

$a = $res->www_authenticate;
ok($a, 'Foo realm="WallyWorld", foo=bar, Bar realm="WallyWorld2", Basic Realm="WallyWorld", foo=bar, bar=baz');

$res->www_authenticate("Basic realm=foo1");
print $res->as_string;

$res->www_authenticate(Basic => {realm => "foo2"});
print $res->as_string;

$res->www_authenticate(Basic => [realm => "foo3", foo=>33],
                       Digest => {nonce=>"bar", foo=>'foo'});
print $res->as_string;

$_ = $res->as_string;

ok(/WWW-Authenticate: Basic realm="foo3", foo=33/);
ok(/WWW-Authenticate: Digest nonce=bar, foo=foo/ ||
   /WWW-Authenticate: Digest foo=foo, nonce=bar/);

