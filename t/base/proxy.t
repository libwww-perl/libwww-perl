use strict;
use warnings;
use Test::More;
use Test::Fatal;

use LWP::UserAgent;
plan tests => 8;

# in case already defined in user's environment
delete $ENV{$_} for qw(REQUEST_METHOD HTTP_PROXY http_proxy CGI_HTTP_PROXY NO_PROXY no_proxy);

for my $varname ( qw(ABSURDLY_NAMED_PROXY MY_PROXY) ) {
    $ENV{ $varname } = "foobar";

    my $ua = LWP::UserAgent->new;
    is(exception{ $ua->env_proxy(); }, undef, "proxy: with env: $varname: no errors");
    delete $ENV{$varname};
}

# simulate CGI environment
{
    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{HTTP_PROXY}     = 'something';
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    is $ua->proxy('http'), undef, 'HTTP_PROXY ignored in CGI environment';
}

{
    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{CGI_HTTP_PROXY} = 'http://proxy.example.org:3128/';
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    is $ua->proxy('http'), 'http://proxy.example.org:3128/',
        'substitute CGI_HTTP_PROXY used in CGI environment';
}

SKIP: {
    skip "Environment variables are case-sensitive on this platform", 1
	if do {
	    local $ENV{TEST_CASE_SENSITIVITY} = "a";
	    local $ENV{test_case_sensitivity} = "b";
	    $ENV{TEST_CASE_SENSITIVITY} eq $ENV{test_case_sensitivity};
	};
    my @warnings;
    local $SIG{__WARN__}   = sub { push @warnings, @_ };
    local $ENV{HTTP_PROXY} = 'http://uppercase-proxy.example.org:3128/';
    local $ENV{http_proxy} = 'http://lowercase-proxy.example.org:3128/';
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    (my $warnings = "@warnings") =~ s{ at .*\n}{};
    is $warnings, qq{Environment contains multiple differing definitions for 'http_proxy'.\nUsing value from 'HTTP_PROXY' (http://uppercase-proxy.example.org:3128/) and ignoring 'http_proxy' (http://lowercase-proxy.example.org:3128/)},
        'expected warning on multiple definitions';
}

{
    my @warnings;
    local $SIG{__WARN__}   = sub { push @warnings, @_ };
    local $ENV{HTTP_PROXY} = 'http://proxy.example.org:3128/';
    local $ENV{http_proxy} = 'http://proxy.example.org:3128/';
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    is_deeply \@warnings, [],
        "No warnings if multiple definitions for 'http_proxy' exist, but with the same value";
}

{
    local $ENV{NO_PROXY} = 'localhost,example.com';
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    is_deeply $ua->{no_proxy}, [qw(localhost example.com)],
        'no_proxy from environment';
}

{
    local $TODO = "Test case for GH #372";
    my @warnings;
    local $SIG{__WARN__}   = sub { push @warnings, @_ };
    local $ENV{FOO} = 'BAR';
    local $ENV{foo} = 'bar';
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    is_deeply \@warnings, [],
        "No warnings for unrelated environment variables";
}
