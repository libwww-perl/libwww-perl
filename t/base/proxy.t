use strict;
use warnings;
use Test::More;
use Test::Fatal;

use LWP::UserAgent;
plan tests => 2;

for my $varname ( qw(ABSURDLY_NAMED_PROXY MY_PROXY) ) {
    $ENV{ $varname } = "foobar";

    my $ua = LWP::UserAgent->new;
    is(exception{ $ua->env_proxy(); }, undef, "proxy: with env: $varname: no errors");
    delete $ENV{$varname};
}
