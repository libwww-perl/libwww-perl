use strict;
use warnings;
use Test::More;

use Config;
use FindBin qw($Bin);
use HTTP::Daemon;
use HTTP::Request;
use IO::Socket;
use LWP::UserAgent;
use URI;
use utf8;

delete $ENV{PERL_LWP_ENV_PROXY};
$| = 1; # autoflush

my $DAEMON;

# allow developer to manually run the daemon and the tests
# separately.  Particularly useful for running with the perl
# debugger.
#
# Run the server like this,
#
# PERL_LWP_ENV_HTTP_TEST_SERVER_TIMEOUT=10000 perl -I lib t/local/http.t daemon
#
# Then the tests like this,
#
# PERL_LWP_ENV_HTTP_TEST_URL=http://127.0.0.1:56957/ perl -I lib t/local/http.t
my $base;
if($ENV{PERL_LWP_ENV_HTTP_TEST_URL})
{
    $base = URI->new($ENV{PERL_LWP_ENV_HTTP_TEST_URL});
    $DAEMON = 1;
}
my $CAN_TEST = (0==system($^X, "$Bin/../../talk-to-ourself"))? 1: 0;

my $D = shift(@ARGV) || '';
if ($D eq 'daemon') {
    daemonize();
}
else {
    # start the daemon and the testing
    if ( $^O ne 'MacOS' and $CAN_TEST and !$base ) {
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

    plan tests => 90;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/0.01 " . $ua->agent);
    $ua->from('gisle@aas.no');

    { # bad request
        my $req = HTTP::Request->new(GET => url("/not_found", $base));
        $req->header(X_Foo => "Bar");
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'bad: got a response');

        ok($res->is_error, 'bad: is_error');
        is($res->code, 404, 'bad: code 404');
        like($res->message, qr/not\s+found/i, 'bad: 404 message');
        # we also expect a few headers
        ok($res->server, 'bad: got server header');
        ok($res->date, 'bad: got date header');
    }
    { # simple echo
        my $req = HTTP::Request->new(GET => url("/echo/path_info?query", $base));
        $req->push_header(Accept => 'text/html');
        $req->push_header(Accept => 'text/plain; q=0.9');
        $req->push_header(Accept => 'image/*');
        $req->push_header(':foo_bar' => 1);
        $req->if_modified_since(time - 300);
        $req->header(Long_text => "This is a very long header line
            which is broken between
            more than one line."
        );
        $req->header(X_Foo => "Bar");

        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'simple echo: got a response');

        ok($res->is_success, 'simple echo: is_success');
        is($res->code, 200, 'simple echo: code 200');
        is($res->message, "OK", 'simple echo: message OK');

        my $content = $res->content;
        my @accept = ($content =~ /^Accept:\s*(.*)/mg);

        like($content, qr/^From:\s*gisle\@aas\.no\n/m, 'simple echo: From good');
        like($content, qr/^Host:/m, 'simple echo: Host good');
        is(@accept, 3, 'simple echo: 3 Accepts');
        like($content, qr/^Accept:\s*text\/html/m, 'simple echo: Accept text/html good');
        like($content, qr/^Accept:\s*text\/plain/m, 'simple echo: Accept text/plain good');
        like($content, qr/^Accept:\s*image\/\*/m, 'simple echo: Accept image good');
        like($content, qr/^If-Modified-Since:\s*\w{3},\s+\d+/m, 'simple echo: modified good');
        like($content, qr/^Long-Text:\s*This.*broken between/m, 'simple echo: long-text good');
        like($content, qr/^Foo-Bar:\s*1\n/m, 'simple echo: Foo-Bar good');
        like($content, qr/^X-Foo:\s*Bar\n/m, 'simple echo: X-Foo good');
        like($content, qr/^User-Agent:\s*Mozilla\/0.01/m, 'simple echo: UserAgent good');
    }
    { # echo with higher level 'get' interface
        my $res = $ua->get(url("/echo/path_info?query", $base),
            Accept => 'text/html',
            Accept => 'text/plain; q=0.9',
            Accept => 'image/*',
            X_Foo => "Bar",
        );
        isa_ok($res, 'HTTP::Response', 'simple echo 2: good response object');
        is($res->code, 200, 'simple echo 2: code 200');
    }
    { # put
        my $res = $ua->put(url("/echo/path_info?query", $base),
            Accept => 'text/html',
            Accept => 'text/plain; q=0.9',
            Accept => 'image/*',
            X_Foo => "Bar",
        );
        isa_ok($res, 'HTTP::Response', 'put: good response object');
        is($res->code, 200, 'put: code 200');
        like($res->content, qr/^From: gisle\@aas.no$/m, 'put: good From');
    }
    { # delete
        my $res = $ua->delete(url("/echo/path_info?query", $base),
            Accept => 'text/html',
            Accept => 'text/plain; q=0.9',
            Accept => 'image/*',
            X_Foo => "Bar",
        );
        isa_ok($res, 'HTTP::Response', 'delete: good response object');
        is($res->code, 200, 'delete: code 200');
        like($res->content, qr/^From: gisle\@aas.no$/m, 'delete: good From');
    }
    { # send file
        my $file = "test-$$.html";
        open(my $fh, '>', $file) or die "Can't create $file: $!";
        binmode $fh or die "Can't binmode $file: $!";
        print {$fh} qq(<html><title>En prøve</title>\n<h1>Dette er en testfil</h1>\nJeg vet ikke hvor stor fila behøver å være heller, men dette\ner sikkert nok i massevis.\n);
        close($fh);

        my $req = HTTP::Request->new(GET => url("/file?name=$file", $base));
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'get file: good response object');

        ok($res->is_success, 'get file: is_success');
        is($res->content_type, 'text/html', 'get file: content type text/html');
        is($res->content_length, 147, 'get file: 147 content length');
        is($res->title, 'En prøve', 'get file: good title');
        like($res->content, qr/å være/, 'get file: good content');

        # A second try on the same file, should fail because we unlink it
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'get file 2nd: good response object');

        ok($res->is_error, 'get file 2nd: is_error');
        is($res->code, 404, 'get file 2nd: code 404');   # not found
    }
    { # try to list current directory
        my $req = HTTP::Request->new(GET => url("/file?name=.", $base));
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'dir list .: good response object');

        # NYI
        is($res->code, 501, 'dir list .: code 501');
    }
    { # redirect
        my $req = HTTP::Request->new(GET => url("/redirect/foo", $base));
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'redirect: good response object');

        ok($res->is_success, 'redirect: is_success');
        like($res->content, qr|/echo/redirect|, 'redirect: content good');
        ok($res->previous->is_redirect, 'redirect: is_redirect');
        is($res->previous->code, 301, 'redirect: code 301');

        # Let's test a redirect loop too
        $req->uri(url("/redirect2", $base));
        $ua->max_redirect(5);
        is($ua->max_redirect(), 5, 'redirect loop: max redirect 5');
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'redirect loop: good response object');

        ok($res->is_redirect, 'redirect loop: is_redirect');
        like($res->header("Client-Warning"), qr/loop detected/i, 'redirect loop: client warning');
        is($res->redirects, 5, 'redirect loop: 5 redirects');

        $ua->max_redirect(0);
        is($ua->max_redirect(), 0, 'redirect loop: max redirect 0');
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'redirect loop: good response object');
        is($res->previous, undef, 'redirect loop: undefined previous');
        is($res->redirects, 0, 'redirect loop: zero redirects');
        $ua->max_redirect(5);
        is($ua->max_redirect(), 5, 'redirect loop: max redirects set back to 5');
    }
    { # basic auth
        my $req = HTTP::Request->new(GET => url("/basic", $base));
        my $res = MyUA->new->request($req);
        isa_ok($res, 'HTTP::Response', 'basicAuth: good response object');

        ok($res->is_success, 'basicAuth: is_success');

        # Let's try with a $ua that does not pass out credentials
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'basicAuth: good response object');
        is($res->code, 401, 'basicAuth: code 401');

        # Let's try to set credentials for this realm
        $ua->credentials($req->uri->host_port, "libwww-perl", "ok 12", "xyzzy");
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'basicAuth: good response object');
        ok($res->is_success, 'basicAuth: is_success');

        # Then illegal credentials
        $ua->credentials($req->uri->host_port, "libwww-perl", "user", "passwd");
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'basicAuth: good response object');
        is($res->code, 401, 'basicAuth: code 401');
    }
    { # digest
        my $req = HTTP::Request->new(GET => url("/digest", $base));
        my $res = MyUA2->new->request($req);
        isa_ok($res, 'HTTP::Response', 'digestAuth: good response object');

        ok($res->is_success, 'digestAuth: is_success');

        # Let's try with a $ua that does not pass out credentials
        $ua->{basic_authentication}=undef;
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'digestAuth: good response object');
        is($res->code, 401, 'digestAuth: code 401');

        # Let's try to set credentials for this realm
        $ua->credentials($req->uri->host_port, "libwww-perl-digest", "ok 23", "xyzzy");
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'digestAuth: good response object');
        ok($res->is_success, 'digestAuth: is_success');

        # Then illegal credentials
        $ua->credentials($req->uri->host_port, "libwww-perl-digest", "user2", "passwd");
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'digestAuth: good response object');
        is($res->code, 401, 'digestAuth: code 401');
    }
    { # proxy
        $ua->proxy(ftp => $base);
        my $req = HTTP::Request->new(GET => "ftp://ftp.perl.com/proxy");
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'proxy: good response object');
        ok($res->is_success, 'proxy: is_success');
    }
    { # post
        my $req = HTTP::Request->new(POST => url("/echo/foo", $base));
        $req->content_type("application/x-www-form-urlencoded");
        $req->content("foo=bar&bar=test");
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'post: good response object');

        my $content = $res->content;
        ok($res->is_success, 'post: is_success');
        like($content, qr/^Content-Length:\s*16$/mi, 'post: content length good');
        like($content, qr/^Content-Type:\s*application\/x-www-form-urlencoded$/mi, 'post: application/x-www-form-urlencoded');
        like($content, qr/^foo=bar&bar=test$/m, 'post: foo=bar&bar=test');

        $req = HTTP::Request->new(POST => url("/echo/foo", $base));
        $req->content_type("multipart/form-data");
        $req->add_part(HTTP::Message->new(["Content-Type" => "text/plain"], "Hi\n"));
        $req->add_part(HTTP::Message->new(["Content-Type" => "text/plain"], "there\n"));
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'post: good response object');
        ok($res->is_success, 'post: is_success');
        ok($res->content =~ /^Content-Type: multipart\/form-data; boundary=/m, 'post: multipart good');
    }
    { # partial
        my $req = HTTP::Request->new(  GET => url("/partial", $base) );
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'partial: good response object');
        ok($res->is_success, 'partial: is_success'); # "a 206 response is considered successful"

        $ua->max_size(3);
        $req = HTTP::Request->new(  GET => url("/partial", $base) );
        $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'partial: good response object');
        ok($res->is_success, 'partial: is_success'); # "a 206 response is considered successful"
        # Put max_size back how we found it.
        $ua->max_size(undef);
        like($res->as_string, qr/Client-Aborted: max_size/, 'partial: aborted'); # Client-Aborted is returned when max_size is given
    }
    { # terminate server
        my $req = HTTP::Request->new(GET => url("/quit", $base));
        my $res = $ua->request($req);
        isa_ok($res, 'HTTP::Response', 'terminate: good response object');

        is($res->code, 503, 'terminate: code is 503');
        like($res->content, qr/Bye, bye/, 'terminate: bye bye');
    }
    {
        my $ua = LWP::UserAgent->new(
            send_te => 0,
        );
        my $res = $ua->request( HTTP::Request->new( GET => url("/echo", $base) ) );
        ok( $res->decoded_content !~ /^TE:/m, "TE header not added" );
    }
}

{
    package MyUA;
    use base 'LWP::UserAgent';
    sub get_basic_credentials {
        my($self, $realm, $uri, $proxy) = @_;
        if ($realm eq "libwww-perl" && $uri->rel($base) eq "basic") {
            return ("ok 12", "xyzzy");
        }
        return undef;
    }
}
{
    package MyUA2;
    use base 'LWP::UserAgent';
    sub get_basic_credentials {
        my($self, $realm, $uri, $proxy) = @_;
        if ($realm eq "libwww-perl-digest" && $uri->rel($base) eq "digest") {
            return ("ok 23", "xyzzy");
        }
        return undef;
    }
}
sub daemonize {
    my %router;
    $router{delete_echo} = sub {
        my($c, $req) = @_;
        $c->send_basic_header(200);
        $c->print("Content-Type: message/http\015\012");
        $c->send_crlf;
        $c->print($req->as_string);
    };
    $router{get_basic} = sub {
        my($c, $r) = @_;
        my($u,$p) = $r->authorization_basic;
        if (defined($u) && $u eq 'ok 12' && $p eq 'xyzzy') {
            $c->send_basic_header(200);
            $c->print("Content-Type: text/plain");
            $c->send_crlf;
            $c->send_crlf;
            $c->print("$u\n");
        }
        else {
            $c->send_basic_header(401);
            $c->print("WWW-Authenticate: Basic realm=\"libwww-perl\"\015\012");
            $c->send_crlf;
        }
    };
    $router{get_digest} = sub {
        my($c, $r) = @_;
        my $auth = $r->authorization;
        my %auth_params;
        if ( defined($auth) && $auth =~ /^Digest\s+(.*)$/ ) {
            %auth_params = map { split /=/ } split /,\s*/, $1;
        }
        if ( %auth_params &&
                $auth_params{username} eq q{"ok 23"} &&
                $auth_params{realm} eq q{"libwww-perl-digest"} &&
                $auth_params{qop} eq "auth" &&
                $auth_params{algorithm} eq q{"MD5"} &&
                $auth_params{uri} eq q{"/digest"} &&
                $auth_params{nonce} eq q{"12345"} &&
                $auth_params{nc} eq "00000001" &&
                defined($auth_params{cnonce}) &&
                defined($auth_params{response})
             ) {
            $c->send_basic_header(200);
            $c->print("Content-Type: text/plain");
            $c->send_crlf;
            $c->send_crlf;
            $c->print("ok\n");
        }
        else {
            $c->send_basic_header(401);
            $c->print("WWW-Authenticate: Digest realm=\"libwww-perl-digest\", nonce=\"12345\", qop=auth\015\012");
            $c->send_crlf;
        }
    };
    $router{get_echo} = sub {
        my($c, $req) = @_;
        $c->send_basic_header(200);
        print $c "Content-Type: message/http\015\012";
        $c->send_crlf;
        print $c $req->as_string;
    };
    $router{get_file} = sub {
        my($c, $r) = @_;
        my %form = $r->uri->query_form;
        my $file = $form{'name'};
        $c->send_file_response($file);
        unlink($file) if $file =~ /^test-/;
    };
    $router{get_partial} = sub {
        my($c) = @_;
        $c->send_basic_header(206);
        print $c "Content-Type: image/jpeg\015\012";
        $c->send_crlf;
        print $c "some fake JPEG content";
    };
    $router{get_proxy} = sub {
        my($c,$r) = @_;
        if ($r->method eq "GET" and $r->uri->scheme eq "ftp") {
            $c->send_basic_header(200);
            $c->send_crlf;
        }
        else {
            $c->send_error;
        }
    };
    $router{get_quit} = sub {
        my($c) = @_;
        $c->send_error(503, "Bye, bye");
        exit;  # terminate HTTP server
    };
    $router{get_redirect} = sub {
        my($c) = @_;
        $c->send_redirect("/echo/redirect");
    };
    $router{get_redirect2} = sub { shift->send_redirect("/redirect3/") };
    $router{get_redirect3} = sub { shift->send_redirect("/redirect2/") };
    $router{post_echo} = sub {
        my($c,$r) = @_;
        $c->send_basic_header;
        $c->print("Content-Type: text/plain");
        $c->send_crlf;
        $c->send_crlf;

        # Do it the hard way to test the send_file
        open(my $fh, '>', "tmp$$") || die;
        binmode($fh);
        print {$fh} $r->as_string;
        close($fh) || die;

        $c->send_file("tmp$$");

        unlink("tmp$$");
    };
    $router{put_echo} = sub {
        my($c, $req) = @_;
        $c->send_basic_header(200);
        $c->print("Content-Type: message/http\015\012");
        $c->send_crlf;
        $c->print($req->as_string);
    };

    # Note: tiemout of 0 is not infinite, so no point in special casing
    # timeout logic.
    my $d = HTTP::Daemon->new(Timeout => $ENV{PERL_LWP_ENV_HTTP_TEST_SERVER_TIMEOUT} || 10, LocalAddr => '127.0.0.1') || die $!;
    print "Pleased to meet you at: <URL:", $d->url, ">\n";
    open(STDOUT, $^O eq 'VMS'? ">nl: " : ">/dev/null");

    while (my $c = $d->accept) {
        while (my $r = $c->get_request) {
            my $p = ($r->uri->path_segments)[1];
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
