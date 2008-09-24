use Test;
plan tests => 6;

use LWP::UserAgent;
$ua = LWP::UserAgent->new();

$ua->protocols_forbidden(['hTtP']);
ok(scalar(@{$ua->protocols_forbidden()}), 1);
ok(@{$ua->protocols_forbidden()}[0], 'hTtP');

$response = $ua->get('http://www.cpan.org/');
ok($response->is_error());
ok(!$ua->is_protocol_supported('http'));
ok(!$ua->protocols_allowed());

$ua->protocols_forbidden(undef);
ok(!$ua->protocols_forbidden());
