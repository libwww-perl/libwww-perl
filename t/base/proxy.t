use strict;
use warnings;
use Test::More;

use LWP::UserAgent;
plan tests => 4;

for my $varname ( qw(ABSURDLY_NAMED_PROXY MY_PROXY) ) {
    $ENV{ $varname } = "foobar";

    my $ua = LWP::UserAgent->new;
    isa_ok($ua, 'LWP::UserAgent', 'new: UserAgent instance');
    my $error = do {
        local $@;
        eval { $ua->env_proxy(); };
        $@;
    };
    is($error, "", "proxy: with env: $varname: no errors");
    delete $ENV{$varname};
}
