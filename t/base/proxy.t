use strict;
use warnings;
use Test::More;
use Test::Fatal qw( exception );

use LWP::UserAgent ();
plan tests => 128;

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

{
    my $proxy_user = '$s3cr=-3t_@dm!m[]]}{_%u$3r';
    my $proxy_pass = '$tr0ng_-%@@2p%41@$$w0rd!';
    my $proxy_user_colon = '$s3cr=-3t_@d:m!m[]]}{_%u$3r';
    my $proxy_pass_colon = '$tr0ng_-%@@2:p%41@$$w0rd!';
    my @proxy_hosts = qw(
        proxy.example.org
        proxy.example.org:3128
        localhost
        localhost:3128
        127.0.0.1
        127.0.0.1:3128
        [::1]
        [::1]:3128
    );
    for my $proxy_host (@proxy_hosts) {
        my $auth_res = 'http://' . encode_value($proxy_user) . ':' . encode_value($proxy_pass) . '@' . $proxy_host;
        my $no_auth_res = 'http://' . $proxy_host;
        my $ua = LWP::UserAgent->new;
        local $ENV{http_proxy} = "http://$proxy_host";
        $ua->env_proxy();
        is(
            $ua->{proxy}{http},
            $no_auth_res,
            'http_proxy from env no auth'
        );
        local $ENV{http_proxy} = "http://$proxy_user:$proxy_pass\@$proxy_host";
        $ua->env_proxy();
        is(
            $ua->{proxy}{http},
            $auth_res,
            'http_proxy from env with auth'
        );
        local $ENV{http_proxy} = "http://$proxy_user_colon:$proxy_pass\@$proxy_host";
        like(
            exception{
                $ua->env_proxy();
            },
            qr/Neither user nor password can contain/,
            'http_proxy from env and user with colon: got exception'
        );
        local $ENV{http_proxy} = "http://$proxy_user:$proxy_pass_colon\@$proxy_host";
        like(
            exception{
                $ua->env_proxy();
            },
            qr/Neither user nor password can contain/,
            'http_proxy from env and password with colon: got exception'
        );
        local $ENV{http_proxy} = "http://$proxy_user:$proxy_pass";
        like(
            exception{
                $ua->env_proxy();
            },
            qr/Bad http proxy specification with/,
            'http_proxy from env and no host: got exception'
        );
        delete $ENV{http_proxy};
        $ua->proxy(['http'], "http://$proxy_host");
        is(
            $ua->{proxy}{http},
            $no_auth_res,
            'http_proxy from method no auth'
        );
        $ua->proxy(['http'], "http://$proxy_user:$proxy_pass\@$proxy_host");
        is(
            $ua->{proxy}{http},
            $auth_res,
            'http_proxy from method with auth'
        );
        like(
            exception{
                $ua->proxy(['http'], "http://$proxy_user_colon:$proxy_pass\@$proxy_host");
            },
            qr/Neither user nor password can contain/,
            'http_proxy from method and user with colon: got exception'
        );
        like(
            exception{
                $ua->proxy(['http'], "http://$proxy_user:$proxy_pass_colon\@$proxy_host");
            },
            qr/Neither user nor password can contain/,
            'http_proxy from method and password with colon: got exception'
        );
        like(
            exception{
                $ua->proxy(['http'], "http://$proxy_user:$proxy_pass");
            },
            qr/Bad http proxy specification with/,
            'http_proxy from method and no host: got exception'
        );
        $ua->proxy('http' => "http://$proxy_host");
        is(
            $ua->{proxy}{http},
            $no_auth_res,
            'http_proxy from method no auth'
        );
        $ua->proxy('http' => "http://$proxy_user:$proxy_pass\@$proxy_host");
        is(
            $ua->{proxy}{http},
            $auth_res,
            'http_proxy from method with auth'
        );
        like(
            exception{
                $ua->proxy('http' => "http://$proxy_user_colon:$proxy_pass\@$proxy_host");
            },
            qr/Neither user nor password can contain/,
            'http_proxy from method and user with colon: got exception'
        );
        like(
            exception{
                $ua->proxy('http' => "http://$proxy_user:$proxy_pass_colon\@$proxy_host");
            },
            qr/Neither user nor password can contain/,
            'http_proxy from method and password with colon: got exception'
        );
        like(
            exception{
                $ua->proxy('http' => "http://$proxy_user:$proxy_pass");
            },
            qr/Bad http proxy specification with/,
            'http_proxy from method and no host: got exception'
        );
    }
}

sub encode_value {
    my $value = shift;
    $value =~ s/([^\w])/sprintf("%%%0x", ord($1))/ge;
    return $value;
}

