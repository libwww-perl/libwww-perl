use strict;
use warnings;

# Regression test: companion hardening to the CVE-2026-8368 cross-origin
# credential strip. A persistent header set via
# default_header()/default_headers must not be re-applied to a cross-origin
# redirect target by prepare_request(). LWP strips
# Authorization/Proxy-Authorization (and Cookie) on redirects; prepare_request
# re-initialises default headers via init_header(), which would silently put
# the stripped credential right back on the cross-origin referral and defeat
# the strip.
#
# These tests override send_request (not simple_request) so prepare_request --
# the code path that re-applies default_headers -- runs for real, while LWP's
# actual redirect loop in request() drives the cross-origin handling.

use Test::More;
use HTTP::Request ();
use HTTP::Response ();

{
    package Test::PrepareUA;
    use parent 'LWP::UserAgent';

    sub new {
        my ($class, %opts) = @_;
        my $responses = delete $opts{_responses} || [];
        my $self = $class->SUPER::new(%opts);
        $self->{_responses} = $responses;
        $self->{_requests}  = [];
        return $self;
    }

    # Capture the request as it is actually put on the wire -- i.e. after
    # prepare_request() has applied default_headers.
    sub send_request {
        my ($self, $req) = @_;
        push @{ $self->{_requests} }, $req->clone;
        my $resp = shift @{ $self->{_responses} }
            || HTTP::Response->new(500, 'no canned response');
        $resp->request($req);
        return $resp;
    }
}

sub make_redirect {
    my ($location) = @_;
    my $r = HTTP::Response->new(302, 'Found');
    $r->header(Location => $location);
    return $r;
}

sub make_ok {
    my $r = HTTP::Response->new(200, 'OK');
    $r->content('done');
    return $r;
}

subtest 'cross-host redirect does not re-apply default Authorization' => sub {
    my $ua = Test::PrepareUA->new(
        _responses => [
            make_redirect('http://attacker.example/loot'),
            make_ok(),
        ],
    );
    $ua->default_header('Authorization'       => 'Bearer s3cr3t');
    $ua->default_header('Proxy-Authorization' => 'Basic cHJveHk6c2VjcmV0');

    my $res = $ua->request(HTTP::Request->new(GET => 'http://victim.example/profile'));

    is(scalar @{ $ua->{_requests} }, 2, 'two requests issued');
    my $first = $ua->{_requests}->[0];
    is($first->header('Authorization'), 'Bearer s3cr3t',
        'first request carries the default Authorization');

    my $followup = $ua->{_requests}->[1];
    is($followup->uri, 'http://attacker.example/loot', 'followup hit redirect target');
    is($followup->header('Authorization'), undef,
        'default Authorization NOT re-applied cross-host');
    is($followup->header('Proxy-Authorization'), undef,
        'default Proxy-Authorization NOT re-applied cross-host');
    is($res->code, 200, 'final response is 200');
};

subtest 'cross-host redirect does not re-apply default Cookie' => sub {
    my $ua = Test::PrepareUA->new(
        _responses => [
            make_redirect('http://attacker.example/loot'),
            make_ok(),
        ],
    );
    $ua->default_header('Cookie' => 'session=s3cr3t');

    $ua->request(HTTP::Request->new(GET => 'http://victim.example/profile'));

    my $followup = $ua->{_requests}->[1];
    is($followup->header('Cookie'), undef,
        'default Cookie NOT re-applied cross-host');
};

subtest 'same-origin redirect keeps default Authorization' => sub {
    my $ua = Test::PrepareUA->new(
        _responses => [
            make_redirect('http://victim.example/profile/new'),
            make_ok(),
        ],
    );
    $ua->default_header('Authorization' => 'Bearer s3cr3t');

    $ua->request(HTTP::Request->new(GET => 'http://victim.example/profile'));

    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'default Authorization preserved same-origin');
};

subtest 'default vs explicit default port is same-origin, keeps Authorization' => sub {
    # http://victim.example -> http://victim.example:80 is the same origin:
    # canonical()/host_port supplies the scheme default port, so the explicit
    # :80 must compare equal and the credential must survive. Locks in the
    # canonicalization the cross-origin comparison relies on.
    my $ua = Test::PrepareUA->new(
        _responses => [
            make_redirect('http://victim.example:80/profile/new'),
            make_ok(),
        ],
    );
    $ua->default_header('Authorization' => 'Bearer s3cr3t');

    $ua->request(HTTP::Request->new(GET => 'http://victim.example/profile'));

    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'default Authorization retained across default/explicit port (same origin)');
};

subtest 'same-origin redirect still drops default Cookie' => sub {
    my $ua = Test::PrepareUA->new(
        _responses => [
            make_redirect('http://victim.example/profile/new'),
            make_ok(),
        ],
    );
    $ua->default_header('Authorization' => 'Bearer s3cr3t');
    $ua->default_header('Cookie'        => 'session=s3cr3t');

    $ua->request(HTTP::Request->new(GET => 'http://victim.example/profile'));

    my $followup = $ua->{_requests}->[1];
    # Cookie is stripped on every redirect, so the default must not bring it
    # back even same-origin, while Authorization (origin-gated) survives.
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'default Authorization retained same-origin');
    is($followup->header('Cookie'), undef,
        'default Cookie dropped even same-origin');
};

subtest 'allow_credentialed_redirects re-applies default Authorization cross-host' => sub {
    my $ua = Test::PrepareUA->new(
        allow_credentialed_redirects => 1,
        _responses => [
            make_redirect('http://attacker.example/loot'),
            make_ok(),
        ],
    );
    $ua->default_header('Authorization' => 'Bearer s3cr3t');
    $ua->default_header('Cookie'        => 'session=s3cr3t');

    $ua->request(HTTP::Request->new(GET => 'http://victim.example/profile'));

    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'default Authorization forwarded under allow_credentialed_redirects');
    # Cookie stripping is unconditional, so the opt-in must not restore it.
    is($followup->header('Cookie'), undef,
        'default Cookie still dropped despite allow_credentialed_redirects');
};

subtest 'non-credential default header still applied on cross-host redirect' => sub {
    my $ua = Test::PrepareUA->new(
        _responses => [
            make_redirect('http://attacker.example/loot'),
            make_ok(),
        ],
    );
    $ua->default_header('X-Trace' => 'abc123');

    $ua->request(HTTP::Request->new(GET => 'http://victim.example/profile'));

    my $followup = $ua->{_requests}->[1];
    is($followup->header('X-Trace'), 'abc123',
        'non-sensitive default header is still applied across redirect');
};

subtest 'multi-hop: default Authorization stays stripped after returning same-origin' => sub {
    # hosta -> hostb (cross, strip) -> hostb/next (same-origin to prior hop).
    # The default Authorization must not reappear on the second hop just
    # because that hop did not itself cross an origin boundary.
    my $ua = Test::PrepareUA->new(
        _responses => [
            make_redirect('http://hostb.example/step'),
            make_redirect('http://hostb.example/final'),
            make_ok(),
        ],
    );
    $ua->default_header('Authorization' => 'Bearer s3cr3t');

    $ua->request(HTTP::Request->new(GET => 'http://hosta.example/start'));

    is(scalar @{ $ua->{_requests} }, 3, 'three requests issued');
    is($ua->{_requests}->[1]->header('Authorization'), undef,
        'Authorization stripped on first cross-origin hop');
    is($ua->{_requests}->[2]->header('Authorization'), undef,
        'Authorization NOT re-applied on same-origin hop after crossing origin');
};

subtest 'multi-hop: default Authorization stays stripped returning to origin' => sub {
    # hosta -> hostb (cross, strip) -> hosta (back to the original origin).
    # The cumulative strip is conservative: once dropped on a foreign hop the
    # credential is not resurrected even when the chain returns home.
    my $ua = Test::PrepareUA->new(
        _responses => [
            make_redirect('http://hostb.example/step'),
            make_redirect('http://hosta.example/final'),
            make_ok(),
        ],
    );
    $ua->default_header('Authorization' => 'Bearer s3cr3t');

    $ua->request(HTTP::Request->new(GET => 'http://hosta.example/start'));

    is(scalar @{ $ua->{_requests} }, 3, 'three requests issued');
    is($ua->{_requests}->[2]->uri, 'http://hosta.example/final',
        'final hop is back on the original origin');
    is($ua->{_requests}->[2]->header('Authorization'), undef,
        'Authorization not resurrected on return to original origin');
};

subtest 'strip tracking does not leak across separate top-level requests' => sub {
    my $ua = Test::PrepareUA->new(
        _responses => [
            # First request: cross-origin redirect that strips Authorization.
            make_redirect('http://attacker.example/loot'),
            make_ok(),
            # Second, independent request: no redirect.
            make_ok(),
        ],
    );
    $ua->default_header('Authorization' => 'Bearer s3cr3t');

    $ua->request(HTTP::Request->new(GET => 'http://victim.example/profile'));
    is($ua->{_requests}->[1]->header('Authorization'), undef,
        'Authorization stripped on first request cross-origin hop');

    # A fresh top-level request must start with a clean strip set.
    $ua->request(HTTP::Request->new(GET => 'http://victim.example/again'));
    is($ua->{_requests}->[2]->header('Authorization'), 'Bearer s3cr3t',
        'default Authorization applied normally on the next top-level request');
};

done_testing;
