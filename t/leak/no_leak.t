use strict;
use warnings;
use Test::More;

# To ensure "no leak" in real LWP code, we should test it against HTTP servers.
# Using a local HTTP::Daemon to avoid SSL and external dependencies that can
# cause false positives in leak detection.
use Config qw( %Config );
use File::Temp ();
use FindBin qw( $Bin );
use HTTP::Daemon ();
use LWP::UserAgent ();
use Test::Needs 'Test::LeakTrace';
use URI ();

plan skip_all => 'skip leak test in COVERAGE' if $ENV{COVERAGE};

delete $ENV{PERL_LWP_ENV_PROXY};
$| = 1; # autoflush

my $DAEMON;
my $base;
my $CAN_TEST = (0==system($^X, "$Bin/../../talk-to-ourself"))? 1: 0;

my $D = shift(@ARGV) || '';
if ($D eq 'daemon') {
    daemonize();
}
else {
    # start the daemon and the testing
    if ( $^O ne 'MacOS' and $CAN_TEST ) {
        my $perl = $Config{'perlpath'};
        $perl = $^X if $^O eq 'VMS' or -x $^X and $^X =~ m,^([a-z]:)?/,i;
        open($DAEMON, "$perl $0 daemon |") or die "Can't exec daemon: $!";
        my $greeting = <$DAEMON> || '';
        if ( $greeting =~ /(<[^>]+>)/ ) {
            $base = URI->new($1);
        }
    }
    _test();
}
exit(0);

sub _test {
    return plan skip_all => "Can't test on this platform" if $^O eq 'MacOS';
    return plan skip_all => 'We cannot talk to ourselves' unless $CAN_TEST;
    return plan skip_all => 'We could not talk to our daemon' unless $DAEMON;
    return plan skip_all => 'No base URI' unless $base;

    plan tests => 2;

    my ($tempfh, $tempfile) = File::Temp::tempfile(UNLINK => 0);
    close $tempfh;

    # Sanity-check that the request actually succeeds, so the leak test below
    # exercises the real success path instead of silently passing on a failed
    # request.
    my $res = LWP::UserAgent->new->get($base, ':content_file' => $tempfile);
    ok($res->is_success, 'request to local daemon succeeded')
        or diag $res->status_line;

    Test::LeakTrace::no_leaks_ok(
        sub {
            my $ua  = LWP::UserAgent->new;
            my $res = $ua->get($base, ':content_file' => $tempfile);
        }
    );

    unlink $tempfile;
}

sub daemonize {
    my $d = HTTP::Daemon->new(Timeout => 10, LocalAddr => '127.0.0.1') || die $!;
    print "Pleased to meet you at: <URL:", $d->url, ">\n";
    open(STDOUT, $^O eq 'VMS'? ">nl: " : ">/dev/null");

    while (my $c = $d->accept) {
        while (my $r = $c->get_request) {
            # Simple response for any request
            $c->send_basic_header(200);
            $c->print("Content-Type: text/plain\015\012");
            $c->send_crlf;
            $c->print("Hello from test server\n");
        }
        $c->close;
        undef($c);
    }
    exit;
}
