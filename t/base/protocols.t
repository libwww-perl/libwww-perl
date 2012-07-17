use strict;
use warnings;
use Test::More;
plan tests => 6;

use LWP::UserAgent;

my $ua = LWP::UserAgent->new();

$ua->protocols_forbidden(['hTtP']);
is(scalar(@{$ua->protocols_forbidden()}), 1,'$ua->protocols_forbidden');
is($ua->protocols_forbidden()->[0], 'hTtP', '$ua->protocols_forbidden->[0]');

my $response = $ua->get('http://www.cpan.org/');
ok($response->is_error(), '$response->is_error');
ok(!$ua->is_protocol_supported('http'), '! $ua->is_protocol_supported("http")');
ok(!$ua->protocols_allowed(),           '! $ua->protocols_allowed');

$ua->protocols_forbidden(undef);
ok(!$ua->protocols_forbidden(),         '$ua->protocols_forbidden(undef)');
