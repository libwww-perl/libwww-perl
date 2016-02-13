use strict;
use warnings;
use Test::More;

use LWP::UserAgent;
use URI;

plan tests => 5;

#
# See if autoloading of protocol schemes work
#
# note no LWP::Protocol::file;

my $url = "file:.";
is(URI->new($url)->file, '.', 'URI of file:. is .');

my $ua = LWP::UserAgent->new;
isa_ok($ua, 'LWP::UserAgent', 'new: UserAgent instance');

$ua->timeout(30);
is($ua->timeout(), 30, 'timeout: set to 30 seconds');

my $response = $ua->get($url);
isa_ok($response, 'HTTP::Response', 'Got a proper response');

ok( $response->is_success(), 'Response was successful' );
unless($response->is_success()) {
    print $response->error_as_HTML;
}
