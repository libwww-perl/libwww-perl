use strict;
use warnings;
use Test::More;

use LWP::UserAgent ();

# Prevent environment from interfering with test:
delete $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
delete $ENV{HTTPS_CA_FILE};
delete $ENV{HTTPS_CA_DIR};
delete $ENV{PERL_LWP_SSL_CA_FILE};
delete $ENV{PERL_LWP_SSL_CA_PATH};
delete $ENV{PERL_LWP_ENV_PROXY};

my $ua = LWP::UserAgent->new;
$ua->default_header( 'Content-Type' => 'application/json' );
$ua->proxy( http => "loopback:" );
$ua->agent("foo/0.1");

is(
    $ua->get("http://www.example.org")->content,
    <<EOT , "request gets proxied" );
GET http://www.example.org
User-Agent: foo/0.1
Content-Type: application/json

EOT

$ua->no_proxy('ample.org');
is_deeply(
    $ua->{no_proxy}, ['ample.org'],
    "no_proxy with partial domain got set"
);

is(
    $ua->get("http://www.example.org")->content,
    <<EOT , "request still gets proxied" );
GET http://www.example.org
User-Agent: foo/0.1
Content-Type: application/json

EOT

$ua->no_proxy();
is_deeply(
    $ua->{no_proxy}, [],
    "no_proxy was cleared"
);
$ua->no_proxy('example.org');
is_deeply(
    $ua->{no_proxy}, ['example.org'],
    "no_proxy with base domain got set"
);

isnt(
    $ua->get("http://www.example.org")->content,
    <<EOT , "request does not get proxied" );
GET http://www.example.org
User-Agent: foo/0.1
Content-Type: application/json

EOT

$ua->no_proxy();
is_deeply(
    $ua->{no_proxy}, [],
    "no_proxy was cleared"
);
$ua->no_proxy('.example.org');
is_deeply(
    $ua->{no_proxy}, ['.example.org'],
    "no_proxy with dot-prefixed base domain got set"
);

isnt(
    $ua->get("http://www.example.org")->content,
    <<EOT , "request does not get proxied" );
GET http://www.example.org
User-Agent: foo/0.1
Content-Type: application/json

EOT

done_testing;
