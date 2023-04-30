#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal qw( exception );

use_ok 'LWP::UserAgent';

my $ua = LWP::UserAgent->new( cookie_jar => {} );
isa_ok $ua->cookie_jar, 'HTTP::Cookies';

$ua = LWP::UserAgent->new;
is $ua->cookie_jar, undef, 'no cookie_jar by default';
$ua->cookie_jar( {} );
note '... but setting one from hash uses default cookie_jar_class';
isa_ok $ua->cookie_jar, 'HTTP::Cookies';

$ua = LWP::UserAgent->new( cookie_jar_class => 'HTTP::CookieJar::LWP' );
$ua->cookie_jar( {} );
isa_ok $ua->cookie_jar, 'HTTP::CookieJar::LWP';

$ua = LWP::UserAgent->new( cookie_jar_class => 'HTTP::CookieJar::LWP' );
is $ua->cookie_jar, undef,
    'no cookie jar by default despite cookie_jar_class being set';

$ua = LWP::UserAgent->new(
    cookie_jar_class => 'HTTP::CookieJar::LWP',
    cookie_jar       => {}
);
note 'cookie_jar and cookie_jar_class can be ued together';
isa_ok $ua->cookie_jar, 'HTTP::CookieJar::LWP';

ok exception {
    LWP::UserAgent->new(
        cookie_jar_class => 'HTTP::CookieMonster::WasHere',
        cookie_jar       => {},
    )
}, 'dies when the cookie_jar_class cannot be loaded';

done_testing();
