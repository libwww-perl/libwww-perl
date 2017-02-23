use strict;
use warnings;
use Test::More;

use LWP::UserAgent;
use HTTP::Request ();
plan tests => 4;

# Prevent environment from interfering with test:
delete $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
delete $ENV{HTTPS_CA_FILE};
delete $ENV{HTTPS_CA_DIR};
delete $ENV{PERL_LWP_SSL_CA_FILE};
delete $ENV{PERL_LWP_SSL_CA_PATH};
delete $ENV{PERL_LWP_ENV_PROXY};

# we can only use HTTP::Request >= 6.07
my $ver = $HTTP::Request::VERSION || '6.00';
my $ver_ok = eval {HTTP::Request->VERSION("6.07");};
diag "Some tests for the PUT method can only be run on ";
diag "HTTP::Request version 6.07 or higher.";
diag "If your version isn't good enough, we'll skip those.";
diag "Your version is $ver and that's ". ($ver_ok ? '' : 'not '). 'good enough';

# default_header 'Content-Type' should be honored in POST/PUT
# if the "Content => 'string'" form is used. Otherwise, x-www-form-urlencoded
# will be used
my $url = "http://www.example.com";
my $ua = LWP::UserAgent->new;
$ua->default_header('Content-Type' => 'application/json');
$ua->proxy(http => "loopback:");
$ua->agent("foo/0.1");

# These forms will all be x-www-form-urlencoded
subtest 'PUT x-www-form-urlencoded' => sub {
    plan skip_all => "HTTP::Request version not high enough" unless $ver_ok;
    plan tests => 4;
    for my $arg (
        [ { cat => 'dog' }             ],
        [ [ cat => 'dog' ]             ],
        [ Content => { cat => 'dog' }, ],
        [ Content => [ cat => 'dog' ], ],
    ) {
        is ($ua->put($url, @$arg)->content, <<"EOT", "put @$arg");
PUT http://www.example.com
User-Agent: foo/0.1
Content-Length: 7
Content-Type: application/x-www-form-urlencoded

cat=dog
EOT
    }
};

# These forms will all be x-www-form-urlencoded
subtest 'POST x-www-form-urlencoded' => sub {
    plan tests => 4;
    for my $arg (
        [ { cat => 'dog' }             ],
        [ [ cat => 'dog' ]             ],
        [ Content => { cat => 'dog' }, ],
        [ Content => [ cat => 'dog' ], ],
    ) {
        is ($ua->post($url, @$arg)->content, <<"EOT", "post @$arg");
POST http://www.example.com
User-Agent: foo/0.1
Content-Length: 7
Content-Type: application/x-www-form-urlencoded

cat=dog
EOT
    }
};

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
