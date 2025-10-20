use strict;
use warnings;
use Test::More;

use LWP::UserAgent ();
use HTTP::Request ();
plan tests => 18;

# Prevent environment from interfering with test:
delete $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
delete $ENV{HTTPS_CA_FILE};
delete $ENV{HTTPS_CA_DIR};
delete $ENV{PERL_LWP_SSL_CA_FILE};
delete $ENV{PERL_LWP_SSL_CA_PATH};
delete $ENV{PERL_LWP_ENV_PROXY};

# default_header 'Content-Type' should be honored in POST/PUT
# if the "Content => 'string'" form is used. Otherwise, x-www-form-urlencoded
# will be used
my $url = "http://www.example.com";
my $ua  = LWP::UserAgent->new;
$ua->default_header('Content-Type' => 'application/json');
$ua->proxy(http => "loopback:");
$ua->agent("foo/0.1");

# These forms will all be x-www-form-urlencoded
subtest 'PATCH x-www-form-urlencoded' => sub {
    plan tests => 4;
    for my $arg (
        [{cat => 'dog'}],
        [[cat => 'dog']],
        [Content => {cat => 'dog'},],
        [Content => [cat => 'dog'],],
        )
    {
        is($ua->patch($url, @$arg)->content, <<"EOT" . "cat=dog", "patch @$arg");
PATCH http://www.example.com
User-Agent: foo/0.1
Content-Length: 7
Content-Type: application/x-www-form-urlencoded

EOT
    }
};

# These forms will all be x-www-form-urlencoded
subtest 'PUT x-www-form-urlencoded' => sub {
    plan tests    => 4;
    for my $arg (
        [{cat => 'dog'}],
        [[cat => 'dog']],
        [Content => {cat => 'dog'},],
        [Content => [cat => 'dog'],],
        )
    {
        is($ua->put($url, @$arg)->content, <<"EOT" . "cat=dog", "put @$arg");
PUT http://www.example.com
User-Agent: foo/0.1
Content-Length: 7
Content-Type: application/x-www-form-urlencoded

EOT
    }
};

# These forms will all be x-www-form-urlencoded
subtest 'POST x-www-form-urlencoded' => sub {
    plan tests => 4;
    for my $arg (
        [{cat => 'dog'}],
        [[cat => 'dog']],
        [Content => {cat => 'dog'},],
        [Content => [cat => 'dog'],],
        )
    {
        is($ua->post($url, @$arg)->content, <<"EOT" . "cat=dog", "post @$arg");
POST http://www.example.com
User-Agent: foo/0.1
Content-Length: 7
Content-Type: application/x-www-form-urlencoded

EOT
    }
};

# These should all use the default
for my $call (qw(post put patch)) {
    my $ucall = uc $call;

    my $arg = [Content => '{"cat":"dog"}'];

    is($ua->$call($url, @$arg)->content, <<"EOT" . '{"cat":"dog"}', "$call @$arg");
$ucall http://www.example.com
User-Agent: foo/0.1
Content-Length: 13
Content-Type: application/json

EOT

}

# Provided Content-Type overrides default
for my $call (qw(post put patch)) {
    my $ucall = uc $call;

    my $arg = ['Content-Type' => 'text/plain', Content => '{"cat":"dog"}'];

    is($ua->$call($url, @$arg)->content,
        <<"EOT" . '{"cat":"dog"}', "$call @$arg with override CT");
$ucall http://www.example.com
User-Agent: foo/0.1
Content-Length: 13
Content-Type: text/plain

EOT

}

# Any non-true content type means use default
for my $ct (0, "", undef) {
    for my $call (qw(post put patch)) {
        my $ucall = uc $call;

        my $arg = ['Content-Type' => $ct, Content => '{"cat":"dog"}'];

        my $desc = defined($ct) ? $ct : "<undef>";

        my @desc_arg = map { defined $_ ? $_ : "<undef>" } @$arg;

        is($ua->$call($url, @$arg)->content,
            <<"EOT" . '{"cat":"dog"}', "$call @desc_arg with false override CT '$desc' uses default");
$ucall http://www.example.com
User-Agent: foo/0.1
Content-Length: 13
Content-Type: application/json

EOT
    }

}
