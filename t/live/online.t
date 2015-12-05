#!perl -w

use strict;
use Test::More;
plan tests => 4;

use_ok('LWP::UserAgent');
my $ua;
ok($ua = LWP::UserAgent->new, '$ua = LWP::UserAgent->new');
ok($ua->is_online,  '$ua->is_online - default');
$ua->protocols_allowed([]);
ok(!$ua->is_online, '$ua->protocols_allowed([])');
