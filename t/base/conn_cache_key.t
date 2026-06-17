use strict;
use warnings;
use Test::More;
use URI ();

use LWP::Protocol::http ();

# Tiny subclass so we can call the private _conn_cache_key without
# spinning up an LWP::UserAgent. Decouples the test from
# LWP::Protocol::new's internals — _conn_cache_key only reads its
# arguments.
{
    package Test::CacheKeyProto;
    use parent -norequire, 'LWP::Protocol::http';
    sub new { bless {}, shift }
}

my $proto = Test::CacheKeyProto->new;

sub key {
    my ($target, $proxy_url) = @_;
    my $url   = URI->new($target);
    my $proxy = URI->new($proxy_url);
    my $ssl_tunnel = $url->scheme eq 'https' ? $url->host_port : undef;
    my ($host, $port) = ($proxy->host, $proxy->port);
    return $proto->_conn_cache_key($host, $port, $ssl_tunnel, $proxy);
}

subtest 'plain HTTP through proxy: userinfo does not split the cache' => sub {
    # Rationale: for non-tunnel requests, every request carries its own
    # headers over the socket, so reuse is safe. Splitting the cache here
    # would defeat keep-alive for callers rotating proxy creds without any
    # correctness benefit.
    my $a = key('http://target/', 'http://user1:pass@proxy:3128');
    my $b = key('http://target/', 'http://user2:pass@proxy:3128');
    is($a, $b, 'plain HTTP cache key ignores proxy userinfo');
    is($a, 'proxy:3128', 'plain HTTP key is just host:port');
};

subtest 'HTTPS tunnel: same userinfo + same target is the same key' => sub {
    my $a = key('https://target:443/', 'http://user:pass@proxy:3128');
    my $b = key('https://target:443/', 'http://user:pass@proxy:3128');
    is($a, $b, 'identical inputs produce identical keys');
};

subtest 'HTTPS tunnel: different userinfo splits the cache' => sub {
    # The actual bug fix. Previously these collided to one key and the
    # second request silently reused a tunnel negotiated with the first
    # token.
    my $a = key('https://target:443/', 'http://token1@proxy:3128');
    my $b = key('https://target:443/', 'http://token2@proxy:3128');
    isnt($a, $b, 'rotating proxy userinfo produces distinct cache keys');
};

subtest 'HTTPS tunnel: missing userinfo vs present userinfo splits' => sub {
    my $a = key('https://target:443/', 'http://proxy:3128');
    my $b = key('https://target:443/', 'http://user:pass@proxy:3128');
    isnt($a, $b, 'absent vs present userinfo are distinguishable');
};

subtest 'HTTPS tunnel: same proxy + different target hosts split' => sub {
    # Already true on master via $ssl_tunnel; verify the helper preserves
    # that.
    my $a = key('https://target1:443/', 'http://user:pass@proxy:3128');
    my $b = key('https://target2:443/', 'http://user:pass@proxy:3128');
    isnt($a, $b, 'different target hosts produce distinct cache keys');
};

subtest 'no proxy: key is just host:port of target' => sub {
    my $url = URI->new('http://target:8080/');
    my $k = $proto->_conn_cache_key($url->host, $url->port, undef, undef);
    is($k, 'target:8080', 'direct connection key is host:port');
};

done_testing;
