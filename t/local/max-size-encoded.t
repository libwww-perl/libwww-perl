use strict;
use warnings;

# Network-free regression tests for the cumulative max_size accounting on the
# "undelivered read" path in LWP::Protocol::http::request().
#
# When a Transfer-Encoding transform (e.g. "gzip, chunked") consumes a read
# without producing decoded output, Net::HTTP::Methods::read_entity_body()
# returns -1 and collect() -- where max_size normally lives -- is never
# reached. request() charges those reads against the cap itself.
#
# These tests drive that path with a fake socket injected through the
# connection cache, so no server or network is required. They cover:
#   * precise accounting: consecutive empty reads accumulate their real
#     encoded byte counts and abort once the cap is exceeded;
#   * cumulative-across-a-delivering-read: a delivering read in between does
#     not reset the counter (guards the removed `$undelivered = 0`);
#   * the https/foreign-socket fallback: a socket that lacks
#     last_entity_bytes() must not crash -- request() falls back to the
#     read-size hint -- and still aborts.

use Test::More;
use LWP::ConnCache ();
use LWP::Protocol::http ();
use LWP::UserAgent ();
use HTTP::Request ();

# ----------------------------------------------------------------------------
# A fake socket exposing just the surface request() touches for a bodyless GET
# whose response has no Content-Length. Reads are driven from a scripted queue.
# ----------------------------------------------------------------------------
{
    package FakeSocketBase;

    sub new {
        my ($class, %args) = @_;
        return bless { reads => $args{reads} || [], last => 0 }, $class;
    }

    # --- connection setup / teardown, all inert for the test ---
    sub can_read                { 0 }       # readable == peer closed; keep it
    sub timeout                 { }
    sub http_version            { }
    sub send_te                 { }
    sub increment_response_count { 1 }
    sub peerhost                { undef }    # so _get_sock_info() skips
    sub get_trailers            { () }
    sub close                   { }

    sub format_request { "GET / HTTP/1.1\015\012\015\012" }

    # pretend the whole request buffer was written in one call
    sub syswrite { return length($_[1]) }

    sub read_response_headers {
        # 200, no Content-Length: request() will read the entity body until EOF
        return (200, 'OK', 'Transfer-Encoding' => 'gzip, chunked');
    }

    sub peer_http_version { '1.1' }

    # Each queued read is [ $return_value, $bytes, $payload ].
    #   $return_value == -1 : transform consumed the read, no decoded output
    #   $return_value  > 0  : delivered $payload
    #   $return_value == 0  : EOF
    sub read_entity_body {
        my $self = shift;                    # ($self, $buf, $size)
        my $spec = shift @{ $self->{reads} } || [ 0, 0, '' ];
        my ($n, $bytes, $payload) = @$spec;
        $self->{last} = $bytes;
        $_[0] = $n > 0 ? $payload : '';      # set the buffer in place
        return $n;
    }
}

# Full socket: exposes last_entity_bytes(), like LWP::Protocol::http::Socket.
{
    package FakeSocketFull;
    our @ISA = ('FakeSocketBase');
    sub last_entity_bytes { $_[0]->{last} }
}

# Foreign socket: no last_entity_bytes(), like LWP::Protocol::https::Socket.
{
    package FakeSocketNoLEB;
    our @ISA = ('FakeSocketBase');
}

sub run_request {
    my ($socket, %args) = @_;
    my $ua = LWP::UserAgent->new(max_size => $args{max_size});
    $ua->conn_cache(LWP::ConnCache->new);
    $ua->conn_cache->deposit('http', 'example.com:80', $socket);

    my $proto = LWP::Protocol::create('http', $ua);
    return $proto->request(HTTP::Request->new(GET => 'http://example.com/'));
}

# ----------------------------------------------------------------------------
# 1. Precise accounting: three empty reads of 400 encoded bytes exceed a
#    1000-byte cap on the third read.
# ----------------------------------------------------------------------------
{
    my $socket = FakeSocketFull->new(reads => [
        [ -1, 400, '' ],
        [ -1, 400, '' ],
        [ -1, 400, '' ],   # cumulative 1200 > 1000 -> abort here
        [  0,   0, '' ],
    ]);
    my $res = run_request($socket, max_size => 1000);
    is($res->header('Client-Aborted'), 'max_size',
        'consecutive empty reads accumulate encoded bytes and abort at the cap');
    is($res->content, '', 'aborted response delivered no content');
}

# ----------------------------------------------------------------------------
# 2. The cap stays cumulative across a delivering read. A reset between the
#    two 600-byte empty reads would keep the total under 1000 and let the
#    response complete -- this asserts it does not.
# ----------------------------------------------------------------------------
{
    my $socket = FakeSocketFull->new(reads => [
        [  -1, 600, ''            ],
        [ 100, 100, 'x' x 100     ],   # delivering read: must NOT reset counter
        [  -1, 600, ''            ],   # cumulative 1200 > 1000 -> abort
        [   0,   0, ''            ],
    ]);
    my $res = run_request($socket, max_size => 1000);
    is($res->header('Client-Aborted'), 'max_size',
        'a delivering read does not reset the undelivered-byte counter');
}

# ----------------------------------------------------------------------------
# 3. A foreign socket without last_entity_bytes() (as https::Socket) must not
#    break on the -1 path; request() falls back to the read-size hint and
#    aborts cleanly. This is the regression guard for the crash that an
#    unconditional $socket->last_entity_bytes call introduced.
#
#    Note the crash does not escape as an exception: collect() wraps the read
#    loop in its own eval, so a missing method turns into a swallowed
#    "Client-Aborted: die" response carrying an X-Died header. So we assert on
#    a clean max_size abort with no X-Died, which the unconditional call fails.
# ----------------------------------------------------------------------------
{
    ok(  LWP::Protocol::http::Socket->can('last_entity_bytes'),
        'http::Socket provides last_entity_bytes');
    ok( !FakeSocketNoLEB->can('last_entity_bytes'),
        'foreign socket (like https::Socket) lacks last_entity_bytes');

    my $socket = FakeSocketNoLEB->new(reads => [
        [ -1, 0, '' ],     # one empty read; $size hint (4096) > cap -> abort
        [  0, 0, '' ],
    ]);
    my $res = run_request($socket, max_size => 1000);
    ok(!$res->header('X-Died'),
        'foreign socket does not die on the undelivered-read path')
        or diag('X-Died: ' . $res->header('X-Died'));
    is($res->header('Client-Aborted'), 'max_size',
        'foreign socket still aborts via the read-size fallback');
}

done_testing;
