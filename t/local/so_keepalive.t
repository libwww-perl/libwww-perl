use strict;
use warnings;
use Test::More;

use LWP::Protocol::http ();
use Socket qw(SOL_SOCKET SO_KEEPALIVE);

# A fake socket that records setsockopt() calls instead of touching the
# network, so we can assert on _new_socket()'s behaviour directly.
{
    package FakeSocket;
    our @CALLS;
    our $SETSOCKOPT_RETURN = 1;    # defined() => success
    sub new {
        my $class = shift;
        @CALLS = ();
        return bless {@_}, $class;
    }
    sub setsockopt {
        my ($self, @args) = @_;
        push @CALLS, [@args];
        return $SETSOCKOPT_RETURN;
    }
    sub blocking { 1 }
    sub close    { 1 }
}

# A protocol subclass whose socket_class returns our fake, so new() never
# opens a real connection.
{
    package MyProto;
    our @ISA = ('LWP::Protocol::http');
    sub socket_class { 'FakeSocket' }
}

sub make_proto {
    my (%ua) = @_;
    return bless { ua => {%ua} }, 'MyProto';
}

sub keepalive_calls {
    return grep { $_->[1] == SO_KEEPALIVE } @FakeSocket::CALLS;
}

subtest 'SO_KEEPALIVE set when a connection cache is in use' => sub {
    local $FakeSocket::SETSOCKOPT_RETURN = 1;
    my $proto = make_proto(conn_cache => 1);
    my $sock  = $proto->_new_socket('localhost', 80, 10);
    ok $sock, 'socket returned';
    my @ka = keepalive_calls();
    is scalar(@ka), 1, 'setsockopt called once for SO_KEEPALIVE';
    is_deeply $ka[0], [SOL_SOCKET, SO_KEEPALIVE, 1],
        'setsockopt called with SOL_SOCKET, SO_KEEPALIVE, 1';
};

subtest 'SO_KEEPALIVE not set without a connection cache' => sub {
    local $FakeSocket::SETSOCKOPT_RETURN = 1;
    my $proto = make_proto(conn_cache => undef);
    my $sock  = $proto->_new_socket('localhost', 80, 10);
    ok $sock, 'socket returned';
    is scalar(keepalive_calls()), 0, 'setsockopt not called for SO_KEEPALIVE';
};

subtest 'setsockopt failure warns but is not fatal' => sub {
    local $FakeSocket::SETSOCKOPT_RETURN = undef;    # simulate failure
    my $proto = make_proto(conn_cache => 1);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $sock = eval { $proto->_new_socket('localhost', 80, 10) };
    ok !$@, 'request did not die on setsockopt failure'
        or diag $@;
    ok $sock, 'socket still returned so the request can proceed';
    is scalar(@warnings), 1, 'one warning emitted';
    like $warnings[0], qr/SO_KEEPALIVE/, 'warning mentions SO_KEEPALIVE';
};

done_testing;
