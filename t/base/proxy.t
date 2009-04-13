#!perl -w

use strict;
use Test;

plan tests => 1;

use LWP::UserAgent;

$ENV{ABSURDLY_NAMED_PROXY} = "foobar";

my $ua = LWP::UserAgent->new;
eval { $ua->env_proxy(); };
ok($@, "");
