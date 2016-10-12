use strict;
use warnings;
use Test::More;

use LWP::UserAgent;

plan tests => 4;

my $ua = LWP::UserAgent->new;

is($ua->protocols_allowed(), undef, 'protocols_allowed: undefined');
ok($ua->is_online, 'is_online: truthy value');

$ua->protocols_allowed([]);
is_deeply($ua->protocols_allowed, [], 'protocols_allowed: empty list');
ok(!$ua->is_online, 'is_online: falsey value');
