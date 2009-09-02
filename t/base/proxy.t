#!perl -w

use strict;
use Test;

plan tests => 2;

use LWP::UserAgent;

for my $varname ( qw(ABSURDLY_NAMED_PROXY MY_PROXY) ) {

    $ENV{ $varname } = "foobar";

    my $ua = LWP::UserAgent->new;
    eval { $ua->env_proxy(); };
    ok($@, "");
}
