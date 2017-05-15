use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use HTTP::Request;
use LWP::UserAgent;
use LWP::ConnCache;

if (!-e "$Bin/config.pl") {
    plan skip_all => 'no net config file';
    exit 0;
}

require "$Bin/config.pl";

my $cache   = LWP::ConnCache->new( total_capacity => 4 );
my $ua      = LWP::UserAgent->new( conn_cache => $cache );
my $ua2     = LWP::UserAgent->new( conn_cache => $cache );

no warnings 'once';
my $netloc  = $net::httpserver || '';
my $script  = ($net::cgidir || '') . "/test";
my $timeout_script = ($net::cgidir || '') . '/timeout';

note 'This script tests whether the timeout used for cached connections';
note 'respects the timeout of the user agent.';
note '';
note 'Case one: Does timeout get set?';
note 'Case two: User agent changes its timeout';
note 'Case three: Multiple user agents share the same cache';
note 'Case four: Check that timeout was applied';

my $request = HTTP::Request->new('GET', "http://$netloc$script", [ 'Connection' => 'Keep-Alive' ]);

$ua->timeout(10);
$ua2->timeout(12);

# First we have to do a test hit.
my $response = $ua->request($request);
if (! $response->is_success) {
    plan skip_all => "Target webserver http://$netloc is down";
    exit 0;
}
elsif ($response->header('Connection') !~ m/keep-alive/i) {
    plan skip_all => 'To run this test, the target webserver must support persistent connections.';
    exit 0;
}

plan tests => 8;

note 'Case one: Does timeout get set?';
my @connections = $cache->get_connections();
is(scalar @connections, 1, "One connection cached");
ok( $connections[0] && $connections[0]->timeout() == 10,
    "After first request, the cached connection has timeout = 10");


note 'Case two: User agent changes its timeout';
note 'Setting user agent timeout to 8 seconds';
$ua->timeout(8);
$response = $ua->request($request);

@connections = $cache->get_connections();
is(scalar @connections, 1, "Still one connection cached");
ok( $connections[0] && $connections[0]->timeout() == 8,
    "Cached connection now has timeout = 8");

note 'Case three: Multiple user agents share the same cache';
note 'Using alternate user agent with timeout = 12 seconds';
$response = $ua2->request($request);
@connections = $cache->get_connections();
is(scalar @connections, 1, "Still one connection cached");
ok( $connections[0] && $connections[0]->timeout() == 12,
    "Cached connection now has timeout = 12");

note 'Case four: Check that timeout was applied';
note 'Setting user agent timeout to 2 seconds';
$ua->timeout(2);

$request = HTTP::Request->new('GET', "http://$netloc$timeout_script", [ 'Connection' => 'Keep-Alive' ]);

# Because the cached connection will be dropped due to the timeout, we have to
# check the actual duration.

my $start_time = time;
$response = $ua->request($request);
my $duration = time - $start_time;

@connections = $cache->get_connections();
is(scalar @connections, 0, "No cached connections remaining");
ok( $duration >= 2 && $duration <= 3, "Timeout applied was 2 seconds");

