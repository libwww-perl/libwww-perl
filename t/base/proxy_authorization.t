use strict;
use warnings;
use HTTP::Headers ();
use Test::More;
use URI ();

use LWP::Protocol::http ();

# Tiny subclass so we can call the private _fixup_header without spinning
# up an LWP::UserAgent. Decouples the test from LWP::Protocol::new's
# internals — _fixup_header only reads its arguments.
{
    package Test::FixupProto;
    use parent -norequire, 'LWP::Protocol::http';
    sub new { bless {}, shift }
}

my $proto = Test::FixupProto->new;
my $url   = URI->new('http://target.example.com/');

subtest 'no proxy userinfo: caller-set Proxy-Authorization preserved' => sub {
    my $proxy = URI->new('http://proxy.example:3128');
    my $h = HTTP::Headers->new('Proxy-Authorization' => 'Bearer caller-token');
    $proto->_fixup_header($h, $url, $proxy);
    is($h->header('Proxy-Authorization'), 'Bearer caller-token',
        'caller-set header is unchanged when proxy URL has no userinfo');
};

subtest 'proxy userinfo, no caller header: userinfo populates' => sub {
    my $proxy = URI->new('http://user:pass@proxy.example:3128');
    my $h = HTTP::Headers->new;
    $proto->_fixup_header($h, $url, $proxy);
    is($h->header('Proxy-Authorization'), 'Basic dXNlcjpwYXNz',
        'userinfo populates Proxy-Authorization when none is set');
};

subtest 'proxy userinfo + caller header: caller wins' => sub {
    my $proxy = URI->new('http://user:pass@proxy.example:3128');
    my $h = HTTP::Headers->new('Proxy-Authorization' => 'Bearer caller-token');
    $proto->_fixup_header($h, $url, $proxy);
    is($h->header('Proxy-Authorization'), 'Bearer caller-token',
        'caller-set header wins over proxy URL userinfo');
};

subtest 'https request URL: userinfo block is skipped entirely' => sub {
    my $https_url = URI->new('https://target.example.com/');
    my $proxy     = URI->new('http://user:pass@proxy.example:3128');
    my $h = HTTP::Headers->new;
    $proto->_fixup_header($h, $https_url, $proxy);
    is($h->header('Proxy-Authorization'), undef,
        'userinfo is not applied when target URL is https (CONNECT path)');
};

done_testing;
