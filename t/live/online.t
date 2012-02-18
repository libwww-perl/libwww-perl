#!perl -w

use strict;
use Test;
plan tests => 2;

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;

ok $ua->is_online;

$ua->protocols_allowed([]);
ok !$ua->is_online;
