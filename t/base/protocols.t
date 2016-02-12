use strict;
use warnings;
use Test::More;

use LWP::UserAgent;
plan tests => 8;

my $ua = LWP::UserAgent->new();
isa_ok($ua, 'LWP::UserAgent', 'new: UserAgent instance');

$ua->protocols_forbidden(['hTtP']);
is(scalar(@{$ua->protocols_forbidden()}), 1,'$ua->protocols_forbidden');
is($ua->protocols_forbidden()->[0], 'hTtP', '$ua->protocols_forbidden->[0]');

my $response = $ua->get('http://www.cpan.org/');
isa_ok($response, 'HTTP::Response', 'Proper response object');
ok($response->is_error(), '$response->is_error');

ok(!$ua->is_protocol_supported('http'), '! $ua->is_protocol_supported("http")');
ok(!$ua->protocols_allowed(), '! $ua->protocols_allowed');

$ua->protocols_forbidden(undef);
ok(!$ua->protocols_forbidden(), '$ua->protocols_forbidden(undef)');
