use strict;
use warnings;
use Test::More;

use LWP::UserAgent;
plan tests => 10;

# Prevent environment from interfering with test:
delete $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
delete $ENV{HTTPS_CA_FILE};
delete $ENV{HTTPS_CA_DIR};
delete $ENV{PERL_LWP_SSL_CA_FILE};
delete $ENV{PERL_LWP_SSL_CA_PATH};
delete $ENV{PERL_LWP_ENV_PROXY};

my $ua = LWP::UserAgent->new;

# default_header 'Content-Type' should be honored in POST/PUT
# if the "Content => 'string'" form is used. Otherwise, x-www-form-urlencoded
# will be used

$ua->default_header('Content-Type' => 'application/json');

$ua->proxy(http => "loopback:");
$ua->agent("foo/0.1");

my $url = "http://www.example.com";

# These forms will all be x-www-form-urlencoded
for my $call (qw(post put)) {
    for my $arg (
        [ { cat => 'dog' }             ],
        [ [ cat => 'dog' ]             ],
        [ Content => { cat => 'dog' }, ],
        [ Content => [ cat => 'dog' ], ],
    ) {
        my $ucall = uc $call;

        is ($ua->$call($url, @$arg)->content, <<"EOT", "$call @$arg");
$ucall http://www.example.com
User-Agent: foo/0.1
Content-Length: 7
Content-Type: application/x-www-form-urlencoded

cat=dog
EOT

    }
}

# These should all use the default
for my $call (qw(post put)) {
    my $ucall = uc $call;

    my $arg = [ Content => '{"cat":"dog"}' ];

    is ($ua->$call($url, @$arg)->content, <<"EOT", "$call @$arg");
$ucall http://www.example.com
User-Agent: foo/0.1
Content-Length: 13
Content-Type: application/json

{"cat":"dog"}
EOT

}

