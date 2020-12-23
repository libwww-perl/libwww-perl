use strict;
use warnings;
use HTTP::Request ();
use LWP::UserAgent ();
use Test::More;

# Prevent environment from interfering with test:
delete $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
delete $ENV{HTTPS_CA_FILE};
delete $ENV{HTTPS_CA_DIR};
delete $ENV{PERL_LWP_SSL_CA_FILE};
delete $ENV{PERL_LWP_SSL_CA_PATH};
delete $ENV{PERL_LWP_ENV_PROXY};

subtest 'proxy settings from the constructor' => sub {
    plan tests => 4;

    my $ua = LWP::UserAgent->new(
        proxy => [
            ftp => 'http://www.sol.no',
            ['http', 'https'] => 'http://www.sol2.no',
        ],
        no_proxy => ['test.com'],
    );

    is($ua->proxy('ftp'), 'http://www.sol.no', q{$ua->proxy("ftp")});

    is($ua->proxy($_), 'http://www.sol2.no', qq{\$ua->proxy("$_)})
        for qw( http https );

    is_deeply($ua->{no_proxy}, ['test.com'], q{no_proxy set to ['test.com']});
};

my $ua = LWP::UserAgent->new;

my $clone = $ua->clone;

like($ua->agent, qr/^libwww-perl/, '$ua->agent');
ok(!defined $ua->proxy(ftp => "http://www.sol.no"), '$ua->proxy(ftp => "http://www.sol.no")');
is($ua->proxy("ftp"), "http://www.sol.no", '$ua->proxy("ftp")');

my @a = $ua->proxy([qw(ftp http wais)], "http://proxy.foo.com");
for (@a) { $_ = "undef" unless defined; }

is("@a", "http://www.sol.no undef undef", '$ua->proxy([qw(ftp http wais)], "http://proxy.foo.com")');
is($ua->proxy("http"), "http://proxy.foo.com", '$ua->proxy("http")');
is(ref($ua->default_headers), "HTTP::Headers", 'ref($ua->default_headers)');

$ua->default_header("Foo" => "bar", "Multi" => [1, 2]);
is($ua->default_headers->header("Foo"), "bar", '$ua->default_headers->header("Foo")');
is($ua->default_header("Foo"),          "bar", '$ua->default_header("Foo")');

# error on malformed request
{
    my $req = HTTP::Request->new('', 'unknown:www.example.com');
    my $res = $ua->simple_request($req);
    like($res->content(), qr/Method missing/, "simple_request: Method Missing: invalid request");

    $req = HTTP::Request->new('HAHAHA', 'unknown:www.example.com');
    $res = $ua->simple_request($req);
    like($res->content(), qr/Protocol scheme 'unknown'/, "simple_request: Invalid Protocol: invalid request");

    $req = HTTP::Request->new('HAHAHA', 'www.example.com');
    $res = $ua->simple_request($req);
    like($res->content(), qr/URL must be absolute/, "simple_request: Invalid Scheme: invalid request");
}

# Try it
$ua->proxy(http => "loopback:");
$ua->agent("foo/0.1");
is($ua->get("http://www.example.com", x => "y")->content, <<EOT , "Full \$ua->get->content");
GET http://www.example.com
User-Agent: foo/0.1
Foo: bar
Multi: 1
Multi: 2
X: y

EOT

ok($ua->post("http://www.example.com", {x => "y", f => "ff"})->content, <<EOT);
POST http://www.example.com
User-Agent: foo/0.1
Content-Length: 8
Content-Type: application/x-www-form-urlencoded
Foo: bar
Multi: 1
Multi: 2

x=y&f=ff
EOT

ok($ua->put("http://www.example.com", [x => "y", f => "ff"])->content, <<EOT);
PUT http://www.example.com
User-Agent: foo/0.1
Content-Length: 8
Content-Type: application/x-www-form-urlencoded
Foo: bar
Multi: 1
Multi: 2

x=y&f=ff
EOT

ok($ua->patch("http://www.example.com", [x => "y", f => "ff"])->content, <<EOT);
PATCH http://www.example.com
User-Agent: foo/0.1
Content-Length: 8
Content-Type: application/x-www-form-urlencoded
Foo: bar
Multi: 1
Multi: 2
x=y&f=ff
EOT

is(ref($clone->{proxy}), 'HASH', 'ref($clone->{proxy})');

is($ua->proxy(http => undef), "loopback:", '$ua->proxy(http => undef)');
is($ua->proxy('http'), undef, "\$ua->proxy('http')");

my $res = $ua->get("data:text/html,%3Chtml%3E%3Chead%3E%3Cmeta%20http-equiv%3D%22Content-Script-Type%22%20content%3D%22text%2Fjavascript%22%3E%3Cmeta%20http-equiv%3D%22Content-Style-Type%22%20content%3D%22text%2Fcss%22%3E%3C%2Fhead%3E%3C%2Fhtml%3E");
ok($res->header("Content-Style-Type", "text/css"),         '$res->header("Content-Style-Type", "text/css")');
ok($res->header("Content-Script-Type", "text/javascript"), '$res->header("Content-Script-Type", "text/javascript")');

is(join(":", $ua->ssl_opts), "verify_hostname", '$ua->ssl_opts');
is($ua->ssl_opts("verify_hostname"),          1, '$ua->ssl_opts("verify_hostname")');
is($ua->ssl_opts("verify_hostname" => 0),     1, '$ua->ssl_opts("verify_hostname" => 0)');
is($ua->ssl_opts("verify_hostname"),          0, '$ua->ssl_opts("verify_hostname")');
is($ua->ssl_opts("verify_hostname" => undef), 0, '$ua->ssl_opts("verify_hostname" => undef)');
is($ua->ssl_opts("verify_hostname"),      undef, '$ua->ssl_opts("verify_hostname")');
is(join(":", $ua->ssl_opts), "", '$ua->ssl_opts');

$ua = LWP::UserAgent->new(ssl_opts => {});
is($ua->ssl_opts("verify_hostname"),      1, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
is($ua->ssl_opts("verify_hostname"),      0, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => { SSL_ca_file => 'cert.dat'});
is($ua->ssl_opts("verify_hostname"),      1, '$ua->ssl_opts("verify_hostname")');
is($ua->ssl_opts("SSL_ca_file"), 'cert.dat', '$ua->ssl_opts("SSL_ca_file")');

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 1;
$ua = LWP::UserAgent->new();
is($ua->ssl_opts("verify_hostname"), 1, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => {});
is($ua->ssl_opts("verify_hostname"), 1, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
is($ua->ssl_opts("verify_hostname"), 0, '$ua->ssl_opts("verify_hostname")');

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$ua = LWP::UserAgent->new();
is($ua->ssl_opts("verify_hostname"), 0, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => {});
is($ua->ssl_opts("verify_hostname"), 0, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
is($ua->ssl_opts("verify_hostname"), 1, '$ua->ssl_opts("verify_hostname")');

delete @ENV{grep /_proxy$/i, keys %ENV}; # clean out any proxy vars

SKIP: {
    skip 'case insensitive ENV on Windows makes this fail', 3, if $^O eq 'MSWin32';
    $ENV{HTTP_PROXY}= "http://example.com";
    $ENV{http_proxy}= "http://otherexample.com";
    my @warn;
    local $SIG{__WARN__}= sub { my ($msg)= @_; $msg=~s/ at .*\z//s; push @warn, $msg };
    # test that we get "HTTP_PROXY" when it is set and differs from "http_proxy".
    $ua = LWP::UserAgent->new;
    is($ua->proxy('http'), undef);
    $ua = LWP::UserAgent->new(env_proxy => 1);
    is($ua->proxy('http'), "http://example.com", q{proxy('http') returns URL});
    is($warn[0],"Environment contains multiple differing definitions for 'http_proxy'.\n"
              ."Using value from 'HTTP_PROXY' (http://example.com) and ignoring 'http_proxy' (http://otherexample.com)");
}

# test that if only one of the two is set we can handle either.
for my $type ('http_proxy', 'HTTP_PROXY') {
    delete $ENV{HTTP_PROXY};
    delete $ENV{http_proxy};
    $ENV{$type} = "http://example.com";
    $ua = LWP::UserAgent->new;
    is($ua->proxy('http'), undef, q{proxy('http') returns undef} );
    $ua = LWP::UserAgent->new(env_proxy => 1);
    is($ua->proxy('http'), "http://example.com", q{proxy('http') returns URL});
}

$ENV{PERL_LWP_ENV_PROXY} = 1;
$ua = LWP::UserAgent->new();
is($ua->proxy('http'), "http://example.com", "\$ua->proxy('http')");
$ua = LWP::UserAgent->new(env_proxy => 0);
is($ua->proxy('http'),                undef, "\$ua->proxy('http')");

$ua = LWP::UserAgent->new();
is($ua->conn_cache, undef, "\$ua->conn_cache");
$ua = LWP::UserAgent->new(keep_alive => undef);
is($ua->conn_cache, undef, "\$ua->conn_cache");
$ua = LWP::UserAgent->new(keep_alive => 0);
is($ua->conn_cache, undef, "\$ua->conn_cache");
$ua = LWP::UserAgent->new(keep_alive => 1);
is($ua->conn_cache->total_capacity, 1, "\$ua->conn_cache->total_capacity");

done_testing();
