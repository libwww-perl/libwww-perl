#!perl

use strict;
use warnings;

use Test::More;

use_ok 'LWP::UserAgent';

my $ua = LWP::UserAgent->new( cookie_jar => {} );
isa_ok $ua->cookie_jar, 'HTTP::Cookies';

$ua = LWP::UserAgent->new( cookie_jar => [] );
isa_ok $ua->cookie_jar, 'HTTP::CookieJar::LWP';

done_testing();
