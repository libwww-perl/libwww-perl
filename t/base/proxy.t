#!perl -w

use strict;
use Test::More;

plan tests => 5;

use_ok(qw/ LWP::UserAgent /);
use vars qw/ $ua /;

for my $varname ( qw(ABSURDLY_NAMED_PROXY MY_PROXY) ) {

    $ENV{ $varname } = "foobar";

    ok($ua = LWP::UserAgent->new, "\$ua = LWP::UserAgent->new  w/ \$ENV{$varname}");

    eval { $ua->env_proxy(); };
    is($@, "", "No \$ua->env_proxy() errors w/ \$ENV{$varname}");
}
