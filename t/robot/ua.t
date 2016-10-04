use strict;
use warnings;
use Test::More;

use Config;
use FindBin qw($Bin);
use HTTP::Daemon;
use HTTP::Request;
use IO::Socket;
use LWP::RobotUA;
use URI;
use utf8;

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
    # First we make ourself a daemon in another process
    # listen to our daemon
    return plan skip_all => "Can't test on this platform" if $^O eq 'MacOS';
    return plan skip_all => 'We cannot talk to ourselves' unless $CAN_TEST;
    return plan skip_all => 'We could not talk to our daemon' unless $DAEMON;
    return plan skip_all => 'No base URI' unless $base;

    plan tests => 14;

    my $ua = LWP::RobotUA->new('lwp-spider/0.1', 'gisle@aas.no');
    $ua->delay(0.05);  # rather quick robot

    { # someplace
        my $req = HTTP::Request->new(GET => url("/someplace", $base));
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'someplace: got a response object');
        ok($res->is_success, 'someplace: is_success');
    }
    { # robots
        my $req = HTTP::Request->new(GET => url("/private/place", $base));
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'robots: got a response object');
        is($res->code, 403, 'robots: code 403');
        like($res->message, qr/robots\.txt/, 'robots: message robots.txt');
    }
    { # foo
        my $req = HTTP::Request->new(GET => url("/foo", $base));
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'robots: got a response object');
        is($res->code, 404, 'robots: code 404');
        # Let the robotua generate "Service unavailable/Retry After response";
        $ua->delay(1);
        $ua->use_sleep(0);
        $req = HTTP::Request->new(GET => url("/foo", $base));
        $res = $ua->request($req);
        is($res->code, 503, 'foo: code 503');
        ok($res->header('Retry-After'), "foo: header Retry-After");
    }
    { # quit
        $ua->delay(0);
        my $req = HTTP::Request->new(GET => url("/quit", $base));
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'quit: got a response object');
        is($res->code, 503, 'quit: code 503');
        like($res->content, qr/Bye, bye/, "quit: content bye bye");

        $ua->delay(1);

        # host_wait() should be around 60s now
        ok( abs($ua->host_wait($base->host_port) - 60) < 5, 'host_wait good');

        # Number of visits to this place should be
        is( $ua->no_visits($base->host_port), 4, 'no_visits good');
    }
}
sub daemonize {
    my %router;
    $router{get_robotstxt} = sub {
        my($c,$r) = @_;
        $c->send_basic_header;
        $c->print("Content-Type: text/plain");
        $c->send_crlf;
        $c->send_crlf;
        $c->print("User-Agent: *\n    Disallow: /private\n    ");
    };
    $router{get_someplace} = sub {
        my($c,$r) = @_;
        $c->send_basic_header;
        $c->print("Content-Type: text/plain");
        $c->send_crlf;
        $c->send_crlf;
        $c->print("Okidok\n");
    };
    $router{get_quit} = sub {
        my($c) = @_;
        $c->send_error(503, "Bye, bye");
        exit;  # terminate HTTP server
    };

    my $d = HTTP::Daemon->new(Timeout => 10, LocalAddr => '127.0.0.1') || die $!;
    print "Pleased to meet you at: <URL:", $d->url, ">\n";
    open(STDOUT, $^O eq 'VMS'? ">nl: " : ">/dev/null");

    while (my $c = $d->accept) {
        while (my $r = $c->get_request) {
            my $p = ($r->uri->path_segments)[1];
            $p =~ s/\W//g;
            my $func = lc($r->method . "_$p");
            if ( $router{$func} ) {
                $router{$func}->($c, $r);
            }
            else {
                $c->send_error(404);
            }
        }
        $c->close;
        undef($c);
    }
    print STDERR "HTTP Server terminated\n";
    exit;
}
sub url {
    my $u = URI->new(@_);
    $u = $u->abs($_[1]) if @_ > 1;
    $u->as_string;
}
