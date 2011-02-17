#!perl -w

use Test;
plan tests => 66;

use HTTP::Cookies;
use HTTP::Request;
use HTTP::Response;

#-------------------------------------------------------------------
# First we check that it works for the original example at
# http://curl.haxx.se/rfc/cookie_spec.html

# Client requests a document, and receives in the response:
# 
#       Set-Cookie: CUSTOMER=WILE_E_COYOTE; path=/; expires=Wednesday, 09-Nov-99 23:12:40 GMT
# 
# When client requests a URL in path "/" on this server, it sends:
# 
#       Cookie: CUSTOMER=WILE_E_COYOTE
# 
# Client requests a document, and receives in the response:
# 
#       Set-Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001; path=/
# 
# When client requests a URL in path "/" on this server, it sends:
# 
#       Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001
# 
# Client receives:
# 
#       Set-Cookie: SHIPPING=FEDEX; path=/fo
# 
# When client requests a URL in path "/" on this server, it sends:
# 
#       Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001
# 
# When client requests a URL in path "/foo" on this server, it sends:
# 
#       Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001; SHIPPING=FEDEX
# 
# The last Cookie is buggy, because both specifications says that the
# most specific cookie must be sent first.  SHIPPING=FEDEX is the
# most specific and should thus be first.

my $year_plus_one = (localtime)[5] + 1900 + 1;

$c = HTTP::Cookies->new;

$req = HTTP::Request->new(GET => "http://1.1.1.1/");
$req->header("Host", "www.acme.com:80");

$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE; path=/ ; expires=Wednesday, 09-Nov-$year_plus_one 23:12:40 GMT");
#print $res->as_string;
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$c->add_cookie_header($req);

ok($req->header("Cookie"), "CUSTOMER=WILE_E_COYOTE");
ok($req->header("Cookie2"), "\$Version=\"1\"");

$res->request($req);
$res->header("Set-Cookie" => "PART_NUMBER=ROCKET_LAUNCHER_0001; path=/");
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/foo/bar");
$c->add_cookie_header($req);

$h = $req->header("Cookie");
ok($h =~ /PART_NUMBER=ROCKET_LAUNCHER_0001/);
ok($h =~ /CUSTOMER=WILE_E_COYOTE/);

$res->request($req);
$res->header("Set-Cookie", "SHIPPING=FEDEX; path=/foo");
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$c->add_cookie_header($req);

$h = $req->header("Cookie");
ok($h =~ /PART_NUMBER=ROCKET_LAUNCHER_0001/);
ok($h =~ /CUSTOMER=WILE_E_COYOTE/);
ok($h !~ /SHIPPING=FEDEX/);


$req = HTTP::Request->new(GET => "http://www.acme.com/foo/");
$c->add_cookie_header($req);

$h = $req->header("Cookie");
ok($h =~ /PART_NUMBER=ROCKET_LAUNCHER_0001/);
ok($h =~ /CUSTOMER=WILE_E_COYOTE/);
ok($h =~ /^SHIPPING=FEDEX;/);

print $c->as_string;


# Second Example transaction sequence:
# 
# Assume all mappings from above have been cleared.
# 
# Client receives:
# 
#       Set-Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001; path=/
# 
# When client requests a URL in path "/" on this server, it sends:
# 
#       Cookie: PART_NUMBER=ROCKET_LAUNCHER_0001
# 
# Client receives:
# 
#       Set-Cookie: PART_NUMBER=RIDING_ROCKET_0023; path=/ammo
# 
# When client requests a URL in path "/ammo" on this server, it sends:
# 
#       Cookie: PART_NUMBER=RIDING_ROCKET_0023; PART_NUMBER=ROCKET_LAUNCHER_0001
# 
#       NOTE: There are two name/value pairs named "PART_NUMBER" due to
#       the inheritance of the "/" mapping in addition to the "/ammo" mapping. 

$c = HTTP::Cookies->new;  # clear it

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->header("Set-Cookie", "PART_NUMBER=ROCKET_LAUNCHER_0001; path=/");

$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$c->add_cookie_header($req);

ok($req->header("Cookie"), "PART_NUMBER=ROCKET_LAUNCHER_0001");

$res->request($req);
$res->header("Set-Cookie", "PART_NUMBER=RIDING_ROCKET_0023; path=/ammo");
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/ammo");
$c->add_cookie_header($req);

ok($req->header("Cookie") =~
       /^PART_NUMBER=RIDING_ROCKET_0023;\s*PART_NUMBER=ROCKET_LAUNCHER_0001/);

print $c->as_string;
undef($c);


#-------------------------------------------------------------------
# When there are no "Set-Cookie" header, then even responses
# without any request URLs connected should be allowed.

$c = HTTP::Cookies->new;
$c->extract_cookies(HTTP::Response->new("200", "OK"));
ok(count_cookies($c), 0);


#-------------------------------------------------------------------
# Then we test with the examples from RFC 2965.
#
# 5.  EXAMPLES

$c = HTTP::Cookies->new;

# 
# 5.1  Example 1
# 
# Most detail of request and response headers has been omitted.  Assume
# the user agent has no stored cookies.
# 
#   1.  User Agent -> Server
# 
#       POST /acme/login HTTP/1.1
#       [form data]
# 
#       User identifies self via a form.
# 
#   2.  Server -> User Agent
# 
#       HTTP/1.1 200 OK
#       Set-Cookie2: Customer="WILE_E_COYOTE"; Version="1"; Path="/acme"
# 
#       Cookie reflects user's identity.

$cookie = interact($c, 'http://www.acme.com/acme/login',
                       'Customer="WILE_E_COYOTE"; Version="1"; Path="/acme"');
ok(!$cookie);

# 
#   3.  User Agent -> Server
# 
#       POST /acme/pickitem HTTP/1.1
#       Cookie: $Version="1"; Customer="WILE_E_COYOTE"; $Path="/acme"
#       [form data]
# 
#       User selects an item for ``shopping basket.''
# 
#   4.  Server -> User Agent
# 
#       HTTP/1.1 200 OK
#       Set-Cookie2: Part_Number="Rocket_Launcher_0001"; Version="1";
#               Path="/acme"
# 
#       Shopping basket contains an item.

$cookie = interact($c, 'http://www.acme.com/acme/pickitem',
		       'Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"');
ok($cookie =~ m(^\$Version="?1"?; Customer="?WILE_E_COYOTE"?; \$Path="/acme"$));

# 
#   5.  User Agent -> Server
# 
#       POST /acme/shipping HTTP/1.1
#       Cookie: $Version="1";
#               Customer="WILE_E_COYOTE"; $Path="/acme";
#               Part_Number="Rocket_Launcher_0001"; $Path="/acme"
#       [form data]
# 
#       User selects shipping method from form.
# 
#   6.  Server -> User Agent
# 
#       HTTP/1.1 200 OK
#       Set-Cookie2: Shipping="FedEx"; Version="1"; Path="/acme"
# 
#       New cookie reflects shipping method.

$cookie = interact($c, "http://www.acme.com/acme/shipping",
		   'Shipping="FedEx"; Version="1"; Path="/acme"');

ok($cookie =~ /^\$Version="?1"?;/);
ok($cookie =~ /Part_Number="?Rocket_Launcher_0001"?;\s*\$Path="\/acme"/);
ok($cookie =~ /Customer="?WILE_E_COYOTE"?;\s*\$Path="\/acme"/);

# 
#   7.  User Agent -> Server
# 
#       POST /acme/process HTTP/1.1
#       Cookie: $Version="1";
#               Customer="WILE_E_COYOTE"; $Path="/acme";
#               Part_Number="Rocket_Launcher_0001"; $Path="/acme";
#               Shipping="FedEx"; $Path="/acme"
#       [form data]
# 
#       User chooses to process order.
# 
#   8.  Server -> User Agent
# 
#       HTTP/1.1 200 OK
# 
#       Transaction is complete.

$cookie = interact($c, "http://www.acme.com/acme/process");
print "FINAL COOKIE: $cookie\n";
ok($cookie =~ /Shipping="?FedEx"?;\s*\$Path="\/acme"/);
ok($cookie =~ /WILE_E_COYOTE/);

# 
# The user agent makes a series of requests on the origin server, after
# each of which it receives a new cookie.  All the cookies have the same
# Path attribute and (default) domain.  Because the request URLs all have
# /acme as a prefix, and that matches the Path attribute, each request
# contains all the cookies received so far.

print $c->as_string;


# 5.2  Example 2
# 
# This example illustrates the effect of the Path attribute.  All detail
# of request and response headers has been omitted.  Assume the user agent
# has no stored cookies.

$c = HTTP::Cookies->new;

# Imagine the user agent has received, in response to earlier requests,
# the response headers
# 
# Set-Cookie2: Part_Number="Rocket_Launcher_0001"; Version="1";
#         Path="/acme"
# 
# and
# 
# Set-Cookie2: Part_Number="Riding_Rocket_0023"; Version="1";
#         Path="/acme/ammo"

interact($c, "http://www.acme.com/acme/ammo/specific",
             'Part_Number="Rocket_Launcher_0001"; Version="1"; Path="/acme"',
             'Part_Number="Riding_Rocket_0023"; Version="1"; Path="/acme/ammo"');

# A subsequent request by the user agent to the (same) server for URLs of
# the form /acme/ammo/...  would include the following request header:
# 
# Cookie: $Version="1";
#         Part_Number="Riding_Rocket_0023"; $Path="/acme/ammo";
#         Part_Number="Rocket_Launcher_0001"; $Path="/acme"
# 
# Note that the NAME=VALUE pair for the cookie with the more specific Path
# attribute, /acme/ammo, comes before the one with the less specific Path
# attribute, /acme.  Further note that the same cookie name appears more
# than once.

$cookie = interact($c, "http://www.acme.com/acme/ammo/...");
ok($cookie =~ /Riding_Rocket_0023.*Rocket_Launcher_0001/);

# A subsequent request by the user agent to the (same) server for a URL of
# the form /acme/parts/ would include the following request header:
# 
# Cookie: $Version="1"; Part_Number="Rocket_Launcher_0001"; $Path="/acme"
# 
# Here, the second cookie's Path attribute /acme/ammo is not a prefix of
# the request URL, /acme/parts/, so the cookie does not get forwarded to
# the server.

$cookie = interact($c, "http://www.acme.com/acme/parts/");
ok($cookie =~ /Rocket_Launcher_0001/);
ok($cookie !~ /Riding_Rocket_0023/);

print $c->as_string;

#-----------------------------------------------------------------------

# Test rejection of Set-Cookie2 responses based on domain, path or port

$c = HTTP::Cookies->new;

# illegal domain (no embedded dots)
$cookie = interact($c, "http://www.acme.com", 'foo=bar; domain=".com"');
ok(count_cookies($c), 0);

# legal domain
$cookie = interact($c, "http://www.acme.com", 'foo=bar; domain="acme.com"');
ok(count_cookies($c), 1);

# illegal domain (host prefix "www.a" contains a dot)
$cookie = interact($c, "http://www.a.acme.com", 'foo=bar; domain="acme.com"');
ok(count_cookies($c), 1);

# legal domain
$cookie = interact($c, "http://www.a.acme.com", 'foo=bar; domain=".a.acme.com"');
ok(count_cookies($c), 2);

# can't use a IP-address as domain
$cookie = interact($c, "http://125.125.125.125", 'foo=bar; domain="125.125.125"');
ok(count_cookies($c), 2);

# illegal path (must be prefix of request path)
$cookie = interact($c, "http://www.sol.no", 'foo=bar; domain=".sol.no"; path="/foo"');
ok(count_cookies($c), 2);

# legal path
$cookie = interact($c, "http://www.sol.no/foo/bar", 'foo=bar; domain=".sol.no"; path="/foo"');
ok(count_cookies($c), 3);

# illegal port (request-port not in list)
$cookie = interact($c, "http://www.sol.no", 'foo=bar; domain=".sol.no"; port="90,100"');
ok(count_cookies($c), 3);

# legal port
$cookie = interact($c, "http://www.sol.no", 'foo=bar; domain=".sol.no"; port="90,100, 80,8080"; max-age=100; Comment = "Just kidding! (\"|\\\\) "');
ok(count_cookies($c), 4);

# port attribute without any value (current port)
$cookie = interact($c, "http://www.sol.no", 'foo9=bar; domain=".sol.no"; port; max-age=100;');
ok(count_cookies($c), 5);

# encoded path
$cookie = interact($c, "http://www.sol.no/foo/", 'foo8=bar; path="/%66oo"');
ok(count_cookies($c), 6);

my $file = "lwp-cookies-$$.txt";
$c->save($file);
$old = $c->as_string;
undef($c);

$c = HTTP::Cookies->new;
$c->load($file);
unlink($file) || warn "Can't unlink $file: $!";

ok($old, $c->as_string);

undef($c);

#
# Try some URL encodings of the PATHs
#
$c = HTTP::Cookies->new;
interact($c, "http://www.acme.com/foo%2f%25/%40%40%0Anew%E5/%E5", 'foo  =   bar; version    =   1');
print $c->as_string;

$cookie = interact($c, "http://www.acme.com/foo%2f%25/@@%0anewå/æøå", "bar=baz; path=\"/foo/\"; version=1");
ok($cookie =~ /foo=bar/);
ok($cookie =~ /^\$version=\"?1\"?/i);

$cookie = interact($c, "http://www.acme.com/foo/%25/@@%0anewå/æøå");
ok(!$cookie);

undef($c);

#
# Try to use the Netscape cookie file format for saving
#
$file = "cookies-$$.txt";
$c = HTTP::Cookies::Netscape->new(file => $file);
interact($c, "http://www.acme.com/", "foo1=bar; max-age=100");
interact($c, "http://www.acme.com/", "foo2=bar; port=\"80\"; max-age=100; Discard; Version=1");
interact($c, "http://www.acme.com/", "foo3=bar; secure; Version=1");
$c->save;
undef($c);

$c = HTTP::Cookies::Netscape->new(file => $file);
ok(count_cookies($c), 1);     # 2 of them discarded on save

ok($c->as_string =~ /foo1=bar/);
undef($c);
unlink($file);


#
# Some additional Netscape cookies test
#
$c = HTTP::Cookies->new;
$req = HTTP::Request->new(POST => "http://foo.bar.acme.com/foo");

# Netscape allows a host part that contains dots
$res = HTTP::Response->new(200, "OK");
$res->header(set_cookie => 'Customer=WILE_E_COYOTE; domain=.acme.com');
$res->request($req);
$c->extract_cookies($res);

# and that the domain is the same as the host without adding a leading
# dot to the domain.  Should not quote even if strange chars are used
# in the cookie value.
$res = HTTP::Response->new(200, "OK");
$res->header(set_cookie => 'PART_NUMBER=3,4; domain=foo.bar.acme.com');
$res->request($req);
$c->extract_cookies($res);

print $c->as_string;

require URI;
$req = HTTP::Request->new(POST => URI->new("http://foo.bar.acme.com/foo"));
$c->add_cookie_header($req);
#print $req->as_string;
ok($req->header("Cookie") =~ /PART_NUMBER=3,4/);
ok($req->header("Cookie") =~ /Customer=WILE_E_COYOTE/);


# Test handling of local intranet hostnames without a dot
$c->clear;
print "---\n";

interact($c, "http://example/", "foo1=bar; PORT; Discard;");
$_=interact($c, "http://example/", 'foo2=bar; domain=".local"');
ok(/foo1=bar/);

$_=interact($c, "http://example/", 'foo3=bar');
$_=interact($c, "http://example/");
print "Cookie: $_\n";
ok(/foo2=bar/);
ok(count_cookies($c), 3);
print $c->as_string;

# Test for empty path
# Broken web-server ORION/1.3.38 returns to the client response like
#
#	Set-Cookie: JSESSIONID=ABCDERANDOM123; Path=
#
# e.g. with Path set to nothing.
# In this case routine extract_cookies() must set cookie to / (root)
print "---\n";
print "Test for empty path...\n";
$c = HTTP::Cookies->new;  # clear it

$req = HTTP::Request->new(GET => "http://www.ants.com/");

$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->header("Set-Cookie" => "JSESSIONID=ABCDERANDOM123; Path=");
print $res->as_string;
$c->extract_cookies($res);
#print $c->as_string;

$req = HTTP::Request->new(GET => "http://www.ants.com/");
$c->add_cookie_header($req);
#print $req->as_string;

ok($req->header("Cookie"), "JSESSIONID=ABCDERANDOM123");
ok($req->header("Cookie2"), "\$Version=\"1\"");


# missing path in the request URI
$req = HTTP::Request->new(GET => URI->new("http://www.ants.com:8080"));
$c->add_cookie_header($req);
#print $req->as_string;

ok($req->header("Cookie"), "JSESSIONID=ABCDERANDOM123");
ok($req->header("Cookie2"), "\$Version=\"1\"");

# test mixing of Set-Cookie and Set-Cookie2 headers.
# Example from http://www.trip.com/trs/trip/flighttracker/flight_tracker_home.xsl
# which gives up these headers:
#
# HTTP/1.1 200 OK
# Connection: close
# Date: Fri, 20 Jul 2001 19:54:58 GMT
# Server: Apache/1.3.19 (Unix) ApacheJServ/1.1.2
# Content-Type: text/html
# Content-Type: text/html; charset=iso-8859-1
# Link: </trip/stylesheet.css>; rel="stylesheet"; type="text/css"
# Servlet-Engine: Tomcat Web Server/3.2.1 (JSP 1.1; Servlet 2.2; Java 1.3.0; SunOS 5.8 sparc; java.vendor=Sun Microsystems Inc.)
# Set-Cookie: trip.appServer=1111-0000-x-024;Domain=.trip.com;Path=/
# Set-Cookie: JSESSIONID=fkumjm7nt1.JS24;Path=/trs
# Set-Cookie2: JSESSIONID=fkumjm7nt1.JS24;Version=1;Discard;Path="/trs"
# Title: TRIP.com Travel - FlightTRACKER
# X-Meta-Description: Trip.com privacy policy
# X-Meta-Keywords: privacy policy

$req = HTTP::Request->new('GET', 'http://www.trip.com/trs/trip/flighttracker/flight_tracker_home.xsl');
$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->push_header("Set-Cookie"  => qq(trip.appServer=1111-0000-x-024;Domain=.trip.com;Path=/));
$res->push_header("Set-Cookie"  => qq(JSESSIONID=fkumjm7nt1.JS24;Path=/trs));
$res->push_header("Set-Cookie2" => qq(JSESSIONID=fkumjm7nt1.JS24;Version=1;Discard;Path="/trs"));
#print $res->as_string;

$c = HTTP::Cookies->new;  # clear it
$c->extract_cookies($res);
print $c->as_string;
ok($c->as_string, <<'EOT');
Set-Cookie3: trip.appServer=1111-0000-x-024; path="/"; domain=.trip.com; path_spec; discard; version=0
Set-Cookie3: JSESSIONID=fkumjm7nt1.JS24; path="/trs"; domain=www.trip.com; path_spec; discard; version=1
EOT

#-------------------------------------------------------------------
# Test if temporary cookies are deleted properly with
# $jar->clear_temporary_cookies()

$req = HTTP::Request->new('GET', 'http://www.perlmeister.com/scripts');
$res = HTTP::Response->new(200, "OK");
$res->request($req);
   # Set session/perm cookies and mark their values as "session" vs. "perm"
   # to recognize them later
$res->push_header("Set-Cookie"  => qq(s1=session;Path=/scripts));
$res->push_header("Set-Cookie"  => qq(p1=perm; Domain=.perlmeister.com;Path=/;expires=Fri, 02-Feb-$year_plus_one 23:24:20 GMT));
$res->push_header("Set-Cookie"  => qq(p2=perm;Path=/;expires=Fri, 02-Feb-$year_plus_one 23:24:20 GMT));
$res->push_header("Set-Cookie"  => qq(s2=session;Path=/scripts;Domain=.perlmeister.com));
$res->push_header("Set-Cookie2" => qq(s3=session;Version=1;Discard;Path="/"));

$c = HTTP::Cookies->new;  # clear jar
$c->extract_cookies($res);
# How many session/permanent cookies do we have?
my %counter = ("session_after" => 0);
$c->scan( sub { $counter{"${_[2]}_before"}++ } );
$c->clear_temporary_cookies();
# How many now?
$c->scan( sub { $counter{"${_[2]}_after"}++ } );
ok($counter{"perm_after"}, $counter{"perm_before"}); # a permanent cookie got lost accidently
ok($counter{"session_after"}, 0); # a session cookie hasn't been cleared
ok($counter{"session_before"}, 3);  # we didn't have session cookies in the first place
#print $c->as_string;


# Test handling of 'secure ' attribute for classic cookies
$c = HTTP::Cookies->new;
$req = HTTP::Request->new(GET => "https://1.1.1.1/");
$req->header("Host", "www.acme.com:80");

$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE ; secure ; path=/");
#print $res->as_string;
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.acme.com/");
$c->add_cookie_header($req);

ok(!$req->header("Cookie"));

$req->uri->scheme("https");
$c->add_cookie_header($req);

ok($req->header("Cookie"), "CUSTOMER=WILE_E_COYOTE");

#print $req->as_string;
#print $c->as_string;


$req = HTTP::Request->new(GET => "ftp://ftp.activestate.com/");
$c->add_cookie_header($req);
ok(!$req->header("Cookie"));

$req = HTTP::Request->new(GET => "file:/etc/motd");
$c->add_cookie_header($req);
ok(!$req->header("Cookie"));

$req = HTTP::Request->new(GET => "mailto:gisle\@aas.no");
$c->add_cookie_header($req);
ok(!$req->header("Cookie"));


# Test cookie called 'exipres' <https://rt.cpan.org/Ticket/Display.html?id=8108>
$c = HTTP::Cookies->new;
$req = HTTP::Request->new("GET" => "http://example.com");
$res = HTTP::Response->new(200, "OK");
$res->request($req);
$res->header("Set-Cookie" => "Expires=10101");
$c->extract_cookies($res);
#print $c->as_string;
ok($c->as_string, <<'EOT');
Set-Cookie3: Expires=10101; path="/"; domain=example.com; discard; version=0
EOT

# Test empty cookie header [RT#29401]
$c = HTTP::Cookies->new;
$res->header("Set-Cookie" => ["CUSTOMER=WILE_E_COYOTE; path=/;", ""]);
#print $res->as_string;
$c->extract_cookies($res);
#print $c->as_string;
ok($c->as_string, <<'EOT');
Set-Cookie3: CUSTOMER=WILE_E_COYOTE; path="/"; domain=example.com; path_spec; discard; version=0
EOT

# Test empty cookie part [RT#38480]
$c = HTTP::Cookies->new;
$res->header("Set-Cookie" => "CUSTOMER=WILE_E_COYOTE;;path=/;");
#print $res->as_string;
$c->extract_cookies($res);
#print $c->as_string;
ok($c->as_string, <<'EOT');
Set-Cookie3: CUSTOMER=WILE_E_COYOTE; path="/"; domain=example.com; path_spec; discard; version=0
EOT

# Test Set-Cookie with version set
$c = HTTP::Cookies->new;
$res->header("Set-Cookie" => "foo=\"bar\";version=1");
#print $res->as_string;
$c->extract_cookies($res);
#print $c->as_string;
$req = HTTP::Request->new(GET => "http://www.example.com/foo");
$c->add_cookie_header($req);
#print $req->as_string;
ok($req->header("Cookie"), "foo=\"bar\"");

# Test cookies that expire far into the future [RT#50147]
$c = HTTP::Cookies->new;
$res->header("Set-Cookie", "PREF=ID=cee18f7c4e977184:TM=1254583090:LM=1254583090:S=Pdb0-hy9PxrNj4LL; expires=Mon, 03-Oct-2211 15:18:10 GMT; path=/; domain=.example.com");
$res->push_header("Set-Cookie", "expired1=1; expires=Mon, 03-Oct-2001 15:18:10 GMT; path=/; domain=.example.com");
$res->push_header("Set-Cookie", "expired2=1; expires=Fri Jan  1 00:00:00 GMT 1970; path=/; domain=.example.com");
$res->push_header("Set-Cookie", "expired3=1; expires=Fri Jan  1 00:00:01 GMT 1970; path=/; domain=.example.com");
$res->push_header("Set-Cookie", "expired4=1; expires=Thu Dec 31 23:59:59 GMT 1969; path=/; domain=.example.com");
$res->push_header("Set-Cookie", "expired5=1; expires=Fri Feb  2 00:00:00 GMT 1950; path=/; domain=.example.com");
$c->extract_cookies($res);
#print $res->as_string;
#print "---\n";
#print $c->as_string;
$req = HTTP::Request->new(GET => "http://www.example.com/foo");
$c->add_cookie_header($req);
#print $req->as_string;
ok($req->header("Cookie"), "PREF=ID=cee18f7c4e977184:TM=1254583090:LM=1254583090:S=Pdb0-hy9PxrNj4LL");

$c->clear_temporary_cookies;
$req = HTTP::Request->new(GET => "http://www.example.com/foo");
$c->add_cookie_header($req);
#print $req->as_string;
ok($req->header("Cookie"), "PREF=ID=cee18f7c4e977184:TM=1254583090:LM=1254583090:S=Pdb0-hy9PxrNj4LL");

# Test merging of cookies
$c = HTTP::Cookies->new;
$res->header("Set-Cookie", "foo=1; path=/");
$c->extract_cookies($res);

$req = HTTP::Request->new(GET => "http://www.example.com/foo");
$req->header("Cookie", "x=bcd");
$c->add_cookie_header($req);
ok($req->header("Cookie"), "x=bcd; foo=1");
$c->add_cookie_header($req);
ok($req->header("Cookie"), "x=bcd; foo=1; foo=1");
#print $req->as_string;


#-------------------------------------------------------------------

sub interact
{
    my $c = shift;
    my $url = shift;
    my $req = HTTP::Request->new(POST => $url);
    $c->add_cookie_header($req);
    my $cookie = $req->header("Cookie");
    my $res = HTTP::Response->new(200, "OK");
    $res->request($req);
    for (@_) { $res->push_header("Set-Cookie2" => $_) }
    $c->extract_cookies($res);
    return $cookie;
}

sub count_cookies
{
    my $c = shift;
    my $no = 0;
    $c->scan(sub { $no++ });
    $no;
}
