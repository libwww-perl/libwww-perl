use strict;
use warnings;

# Regression test for CVE-2026-8368 — LWP::UserAgent cross-origin
# redirect credential leak and related https->http downgrade hardening.

use Test::More;
use HTTP::Request ();
use HTTP::Response ();

{
    package Test::CapturingUA;
    use parent 'LWP::UserAgent';

    sub new {
        my ($class, %opts) = @_;
        my $responses = delete $opts{_responses} || [];
        my $self = $class->SUPER::new(%opts);
        $self->{_responses} = $responses;
        $self->{_requests}  = [];
        return $self;
    }

    sub simple_request {
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

sub build_request {
    my ($url) = @_;
    my $req = HTTP::Request->new(GET => $url);
    $req->header('Authorization'       => 'Bearer s3cr3t');
    $req->header('Proxy-Authorization' => 'Basic cHJveHk6c2VjcmV0');
    return $req;
}

subtest 'scaffold: single request returns canned 200' => sub {
    my $ua = Test::CapturingUA->new(_responses => [make_ok()]);
    my $res = $ua->request(build_request('http://example/'));
    is($res->code, 200, 'got 200');
    is(scalar @{ $ua->{_requests} }, 1, 'one request captured');
};

subtest 'cross-host redirect strips Authorization + Proxy-Authorization' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('http://attacker.example/loot'),
            make_ok(),
        ],
    );
    my $res = $ua->request(build_request('http://victim.example/profile'));

    is(scalar @{ $ua->{_requests} }, 2, 'two requests issued');
    my $followup = $ua->{_requests}->[1];
    is($followup->uri, 'http://attacker.example/loot', 'followup hit redirect target');
    is($followup->header('Authorization'),       undef, 'Authorization stripped cross-host');
    is($followup->header('Proxy-Authorization'), undef, 'Proxy-Authorization stripped cross-host');
    is($res->code, 200, 'final response is 200');
};

subtest 'different port counts as cross-origin' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('http://victim.example:8080/x'),
            make_ok(),
        ],
    );
    $ua->request(build_request('http://victim.example/profile'));
    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'),       undef, 'Authorization stripped on port change');
    is($followup->header('Proxy-Authorization'), undef, 'Proxy-Authorization stripped on port change');
};

subtest 'different scheme counts as cross-origin' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('https://victim.example/profile'),
            make_ok(),
        ],
    );
    $ua->request(build_request('http://victim.example/profile'));
    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'),       undef, 'Authorization stripped on scheme change');
    is($followup->header('Proxy-Authorization'), undef, 'Proxy-Authorization stripped on scheme change');
};

subtest 'constructor accepts allow_credentialed_redirects under -w' => sub {
    local $SIG{__WARN__} = sub { fail("unexpected warning: $_[0]") };
    local $^W = 1;
    my $ua = LWP::UserAgent->new(allow_credentialed_redirects => 1);
    pass('constructor accepted allow_credentialed_redirects without warnings');
    is($ua->{allow_credentialed_redirects}, 1, 'allow_credentialed_redirects stored');
    is($ua->allow_credentialed_redirects, 1, 'accessor reads stored value');
};

subtest 'same-origin redirect keeps credential headers' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('http://victim.example/profile/new'),
            make_ok(),
        ],
    );
    $ua->request(build_request('http://victim.example/profile'));
    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'Authorization preserved same-origin');
    is($followup->header('Proxy-Authorization'), 'Basic cHJveHk6c2VjcmV0',
        'Proxy-Authorization preserved same-origin');
};

subtest 'host comparison is case-insensitive' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('http://VICTIM.example/profile/new'),
            make_ok(),
        ],
    );
    $ua->request(build_request('http://victim.example/profile'));
    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'Authorization preserved when host differs only in case');
};

subtest 'default-port normalization treats http://h/ and http://h:80/ as same origin' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('http://victim.example:80/profile/new'),
            make_ok(),
        ],
    );
    $ua->request(build_request('http://victim.example/profile'));
    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'Authorization preserved when explicit port matches default');
};

subtest 'allow_credentialed_redirects opt-out via constructor' => sub {
    my $ua = Test::CapturingUA->new(
        allow_credentialed_redirects => 1,
        _responses => [
            make_redirect('http://attacker.example/loot'),
            make_ok(),
        ],
    );
    $ua->request(build_request('http://victim.example/profile'));
    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'Authorization forwarded when allow_credentialed_redirects is true');
};

subtest 'allow_credentialed_redirects opt-out via accessor' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('http://attacker.example/loot'),
            make_ok(),
        ],
    );
    $ua->allow_credentialed_redirects(1);
    $ua->request(build_request('http://victim.example/profile'));
    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), 'Bearer s3cr3t',
        'Authorization forwarded after $ua->allow_credentialed_redirects(1)');
};

subtest 'https -> http downgrade is refused' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('http://victim.example/profile'),
            make_ok(),
        ],
    );
    my $res = $ua->request(build_request('https://victim.example/profile'));

    is(scalar @{ $ua->{_requests} }, 1, 'follow-up request was NOT issued');
    is($res->code, 302, 'returned the original 302 response');
    like(
        $res->header('Client-Warning'),
        qr/Refusing https->http redirect/,
        'Client-Warning explains the refusal'
    );
};

subtest 'allow_downgrade opts in to https -> http (constructor)' => sub {
    my $ua = Test::CapturingUA->new(
        allow_downgrade => 1,
        _responses => [
            make_redirect('http://victim.example/profile'),
            make_ok(),
        ],
    );
    my $res = $ua->request(build_request('https://victim.example/profile'));

    is(scalar @{ $ua->{_requests} }, 2, 'follow-up request was issued');
    is($res->code, 200, 'final response is 200 OK');
    my $followup = $ua->{_requests}->[1];
    is($followup->header('Authorization'), undef,
        'Authorization still stripped (scheme change is cross-origin)');
};

subtest 'allow_downgrade opts in to https -> http (accessor)' => sub {
    my $ua = Test::CapturingUA->new(
        _responses => [
            make_redirect('http://victim.example/profile'),
            make_ok(),
        ],
    );
    $ua->allow_downgrade(1);
    my $res = $ua->request(build_request('https://victim.example/profile'));

    is(scalar @{ $ua->{_requests} }, 2, 'follow-up issued after accessor set');
    is($res->code, 200, 'final response is 200 OK');
};

done_testing;
