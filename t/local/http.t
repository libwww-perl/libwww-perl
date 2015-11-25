# -*- perl -*-

use strict;
use warnings;
use Config;
use HTTP::Daemon;
use HTTP::Request;
use HTTP::Status;
use IO::Handle;
use IO::Socket;
use Test::More;
use URI;
use FindBin qw($Bin);
use utf8;

STDOUT->autoflush(1);
sub httpd_get_basic {
    my($c, $r) = @_;
    #print STDERR $r->as_string;
    my($u,$p) = $r->authorization_basic;
    if (defined($u) && $u eq 'ok 12' && $p eq 'xyzzy') {
        $c->send_basic_header(200);
    print $c "Content-Type: text/plain";
    $c->send_crlf;
    $c->send_crlf;
    $c->print("$u\n");
    }
    else {
        $c->send_basic_header(401);
    $c->print("WWW-Authenticate: Basic realm=\"libwww-perl\"\015\012");
    $c->send_crlf;
    }
}
sub httpd_get_digest {
    my($c, $r) = @_;
    #print STDERR $r->as_string;
    my $auth = $r->authorization;
    my %auth_params;
    if ( defined($auth) && $auth =~ /^Digest\s+(.*)$/ ) {
        %auth_params = map { split /=/ } split /,\s*/, $1;
    }
    if ( %auth_params &&
            $auth_params{username} eq "\"ok 23\"" &&
            $auth_params{realm} eq "\"libwww-perl-digest\"" &&
            $auth_params{qop} eq "auth" &&
            $auth_params{algorithm} eq "\"MD5\"" &&
            $auth_params{uri} eq "\"/digest\"" &&
            $auth_params{nonce} eq "\"12345\"" &&
            $auth_params{nc} eq "00000001" &&
            defined($auth_params{cnonce}) &&
            defined($auth_params{response})
         ) {
        $c->send_basic_header(200);
        print $c "Content-Type: text/plain";
        $c->send_crlf;
        $c->send_crlf;
        $c->print("ok\n");
    }
    else {
        $c->send_basic_header(401);
        $c->print("WWW-Authenticate: Digest realm=\"libwww-perl-digest\", nonce=\"12345\", qop=auth\015\012");
        $c->send_crlf;
    }
}
sub httpd_get_echo {
    my($c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: message/http\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}
sub httpd_get_file {
    my($c, $r) = @_;
    my %form = $r->uri->query_form;
    my $file = $form{'name'};
    $c->send_file_response($file);
    unlink($file) if $file =~ /^test-/;
}
sub httpd_get_partial {
   my($c) = @_;
    $c->send_basic_header(206);
    print $c "Content-Type: image/jpeg\015\012";
    $c->send_crlf;
    print $c "some fake JPEG content";

}
sub httpd_get_proxy {
   my($c,$r) = @_;
   if ($r->method eq "GET" and
       $r->uri->scheme eq "ftp") {
       $c->send_basic_header(200);
       $c->send_crlf;
   }
   else {
       $c->send_error;
   }
}
sub httpd_get_quit {
    my($c) = @_;
    $c->send_error(503, "Bye, bye");
    exit;  # terminate HTTP server
}
sub httpd_get_redirect { shift->send_redirect("/echo/redirect") }
sub httpd_get_redirect2 { shift->send_redirect("/redirect3/") }
sub httpd_get_redirect3 { shift->send_redirect("/redirect2/") }
sub httpd_post_echo {
   my($c,$r) = @_;
   $c->send_basic_header;
   $c->print("Content-Type: text/plain");
   $c->send_crlf;
   $c->send_crlf;

   # Do it the hard way to test the send_file
   open(TMP, ">tmp$$") || die;
   binmode(TMP);
   print TMP $r->as_string;
   close(TMP) || die;

   $c->send_file("tmp$$");

   unlink("tmp$$");
}
sub httpd_put_echo {
    my($c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: message/http\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}
sub httpd_delete_echo {
    my($c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: message/http\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}
sub url {
   my $u = URI->new(@_);
   $u = $u->abs($_[1]) if @_ > 1;
   $u->as_string;
}


# first things first, do we need to daemonize?
if (@ARGV && $ARGV[0] && $ARGV[0] eq 'daemon') {
    no strict 'refs';
    my $d = HTTP::Daemon->new(Timeout => 10, LocalAddr => '127.0.0.1');

    print "Please to meet you at: <URL:", $d->url, ">\n";
    open(STDOUT, $^O eq 'VMS'? ">nl: " : ">/dev/null");

    while (my $c = $d->accept) {
        while( my $r = $c->get_request ) {
            my $p = ($r->uri->path_segments)[1];
            my $func = lc("httpd_" . $r->method . "_$p");
            if (defined &$func) {
                $func->($c, $r);
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

delete $ENV{PERL_LWP_ENV_PROXY};

#plan skip_all => "No net config file $Bin/config.pl" unless -e "$Bin/config.pl";
plan skip_all => 'No testing on Macs pre-OS X' if $^O eq "MacOS";
plan skip_all => "Can't talk to ourself (misconfigured system)"
    if (0 != system($^X, "$Bin/../../talk-to-ourself"));

use_ok('LWP::UserAgent');

# show LWP debug info
print "\$LWP::UserAgent::VERSION - $LWP::UserAgent::VERSION\n";
for(@INC){-f "$_/LWP/UserAgent.pm" and print "$_/LWP/UserAgent.pm\n" and last;}

# figure out what perl app to execute to start the daemon
my $perl = $Config{'perlpath'};
$perl = $^X if $^O eq 'VMS' or -x $^X and $^X =~ m,^([a-z]:)?/,i;

# start the daemon
open(my $daemon, "$perl $0 daemon |") or die "Can't exec daemon: $!";
ok($daemon, 'daemon: seemingly got a daemon');

my $greeting = <$daemon>;
ok($greeting, 'daemon: got a proper greeting');
print "Greeting: $greeting";
$greeting =~ /(<[^>]+>)/;

my $base = URI->new($1);
isa_ok($base, 'URI', 'Properly created the URI');
print "Will access HTTP server at $base\n";

my $ua = LWP::UserAgent->new();   # create a useragent to test
isa_ok($ua,'LWP::UserAgent', 'new UserAgent');

$ua->agent("Mozilla/0.01 " . $ua->agent);
$ua->from('gisle@aas.no');

{ # bad request
    my $req = HTTP::Request->new(GET => url("/not_found", $base));
    isa_ok($req, 'HTTP::Request', 'not found: Created a new request');
    $req->header(X_Foo => "Bar");
    my $res = $ua->request($req);
    isa_ok($res, 'HTTP::Response', 'not found: Got a response');
    ok($res->is_error, 'not found: is_error');
    is($res->code, 404, 'not found: response code 404');
    like($res->message, qr/not\s+found/i, 'not found: 404 message');
    # we also expect a few headers
    ok($res->server, 'not found: Got a proper server header');
    ok($res->date, 'not found: Got a proper date from the server');
}

{ # echo request
    my $req = HTTP::Request->new(GET => url("/echo/path_info?query", $base));
    isa_ok($req, 'HTTP::Request', 'echo: Created a new request');
    $req->push_header(Accept => 'text/html');
    $req->push_header(Accept => 'text/plain; q=0.9');
    $req->push_header(Accept => 'image/*');
    $req->push_header(':foo_bar' => 1);
    $req->if_modified_since(time - 300);
    $req->header(Long_text => 'This is a very long header line
    which is broken between
    more than one line.');
    $req->header(X_Foo => "Bar");

    my $res = $ua->request($req);
    isa_ok($res, 'HTTP::Response', 'echo: Got a response');
    #print $res->as_string;

    ok($res->is_success, 'echo: response successful');
    is($res->code, 200, 'echo: status code 200');
    is($res->message, "OK", 'echo: message OK');

    my $content = $res->content;
    my @accept;
    push @accept, $1 while ( $content =~ /^Accept:\s*(.*)/mg );

    like($content, qr/^From:\s*gisle\@aas\.no\n/m, 'echo: proper from');
    like($content, qr/^Host:/m, 'echo: host');
    is(@accept, 3, 'echo: 3 items in accept');
    like($content, qr/^Accept:\s*text\/html/m, 'echo: accept head text/html');
    like($content, qr/^Accept:\s*text\/plain/m, 'echo: accept head text/plain');
    like($content, qr/^Accept:\s*image\/\*/m, 'echo: accept head image');
    like($content, qr/^If-Modified-Since:\s*\w{3},\s+\d+/m, 'echo: head modified');
    like($content, qr/^Long-Text:\s*This.*broken between/m, 'echo: head long');
    like($content, qr/^Foo-Bar:\s*1\n/m, 'echo: head foo-bar');
    like($content, qr/^X-Foo:\s*Bar\n/m, 'echo: head x-foo');
    like($content, qr/^User-Agent:\s*Mozilla\/0.01/m, 'echo: head useragent');

    # Try it with the higher level 'get' interface
    $res = $ua->get(url("/echo/path_info?query", $base),
        Accept => 'text/html',
        Accept => 'text/plain; q=0.9',
        Accept => 'image/*',
        X_Foo => "Bar",
    );
    isa_ok($res,'HTTP::Response', 'echo: other get interface proper response');
    is($res->code, 200, 'echo: response code 200');
    like($res->content, qr/^From: gisle\@aas.no$/m, 'echo: head from');

    # echo put
    # Try it with the higher level 'put' interface
    $res = $ua->put(url("/echo/path_info?query", $base),
        Accept => 'text/html',
        Accept => 'text/plain; q=0.9',
        Accept => 'image/*',
        X_Foo => "Bar",
    );
    isa_ok($res,'HTTP::Response', 'echo: put - proper response');
    is($res->code, 200, 'echo: put - response code 200');
    like($res->content, qr/^From: gisle\@aas.no$/m, 'echo: put - header from');

    # echo delete
    # Try it with the higher level 'put' interface
    $res = $ua->delete(url("/echo/path_info?query", $base),
        Accept => 'text/html',
        Accept => 'text/plain; q=0.9',
        Accept => 'image/*',
        X_Foo => "Bar",
    );
    isa_ok($res,'HTTP::Response', 'echo: delete - proper response');
    is($res->code, 200, 'echo: delete - response code 200');
    like($res->content, qr/^From: gisle\@aas.no$/m, 'echo: delete - header from');
}

{ # send file
    my $file = "test-$$.html";
    open(my $fh, '>:raw', $file) or die "Can't create $file: $!";
    ok($fh, 'file: Got a proper file handle');
    my $string = join "\n", '<html><title>En prøve</title>',
        '<h1>Dette er en testfil</h1>',
        'Jeg vet ikke hvor stor fila behøver å være heller, men dette',
        'er sikkert nok i massevis.';
    $fh->print($string);
    close($fh);

    my $req = HTTP::Request->new(GET => url("/file?name=$file", $base));
    isa_ok($req, 'HTTP::Request', 'file: created a Request');
    my $res = $ua->request($req);
    isa_ok($res, 'HTTP::Response', 'file: got a response');
    #print $res->as_string;

    ok($res->is_success, 'file: successful response');
    is($res->content_type, 'text/html', 'file: content type = text/html');
    is($res->content_length, 146, 'file: length = 146');
    is($res->title, 'En prøve', 'file: proper title');
    like($res->content, qr/å være/, 'file: proper content');

    # A second try on the same file, should fail because we unlink it
    $res = $ua->request($req);
    isa_ok($res, 'HTTP::Response', 'file: second response');
    #print $res->as_string;
    ok($res->is_error, 'file: errored because it was deleted');
    is($res->code, 404, 'file: response code 404');   # not found

    # Then try to list current directory
    $req = HTTP::Request->new(GET => url("/file?name=.", $base));
    isa_ok($req, 'HTTP::Request', 'file: request created for dir content');
    $res = $ua->request($req);
    isa_ok($res, 'HTTP::Response', 'file: got a response');
    #print $res->as_string;
    is($res->code, 501, 'file: response code 501');   # NYI
}

{ # redirect
    my $req = HTTP::Request->new(GET => url("/redirect/foo", $base));
    my $res = $ua->request($req);
    #print $res->as_string;

    ok($res->is_success, 'redirect: is success');
    like($res->content, qr|/echo/redirect|, 'redirect: contents contain echo/redirect');
    ok($res->previous->is_redirect, 'redirect: is redirect');
    is($res->previous->code, 301, 'redirect: response code 301');

    # Let's test a redirect loop too

    $req->uri(url("/redirect2", $base));
    $ua->max_redirect(5);
    $res = $ua->request($req);
    #print $res->as_string;
    ok($res->is_redirect, 'redirect: is redirect');
    like($res->header("Client-Warning"), qr/loop detected/i, 'redirect: header loop');
    is($res->redirects, 5, 'redirect: 5 max redirects');

    $ua->max_redirect(0);
    $res = $ua->request($req);
    is($res->previous, undef, 'redirect: undefined previous');
    is($res->redirects, 0, 'redirect: zero redirects');
    $ua->max_redirect(5);
}

{ # basic
    {
       package MyUA;
       use base 'LWP::UserAgent';
       sub get_basic_credentials {
          my($self, $realm, $uri, $proxy) = @_;
          if ($realm eq "libwww-perl" && $uri->rel($base) eq "basic") {
              return ("ok 12", "xyzzy");
          }
          else {
              return undef;
          }
       }
    }
    my $req = HTTP::Request->new(GET => url("/basic", $base));
    my $res = MyUA->new->request($req);
    #print $res->as_string;

    ok($res->is_success, 'basic auth: success');
    #print $res->content;

    # Let's try with a $ua that does not pass out credentials
    $res = $ua->request($req);
    is($res->code, 401, 'basic auth: respone code 401');

    # Let's try to set credentials for this realm
    $ua->credentials($req->uri->host_port, "libwww-perl", "ok 12", "xyzzy");
    $res = $ua->request($req);
    ok($res->is_success, 'basic auth: is success');

    # Then illegal credentials
    $ua->credentials($req->uri->host_port, "libwww-perl", "user", "passwd");
    $res = $ua->request($req);
    is($res->code, 401, 'basic auth: response code 401');
}

{ # digest
    {
        package MyUA2;
        use base 'LWP::UserAgent';
        sub get_basic_credentials {
            my($self, $realm, $uri, $proxy) = @_;
            if ($realm eq "libwww-perl-digest" && $uri->rel($base) eq "digest") {
                return ("ok 23", "xyzzy");
            }
            else {
                return undef;
            }
        }
    }
    my $req = HTTP::Request->new(GET => url("/digest", $base));
    my $res = MyUA2->new->request($req);
    #print STDERR $res->as_string;

    ok($res->is_success, 'digest auth: is success');
    #print $res->content;

    # Let's try with a $ua that does not pass out credentials
    $ua->{basic_authentication}=undef;
    $res = $ua->request($req);
    is($res->code, 401, 'digest auth: respone code 401');

    # Let's try to set credentials for this realm
    $ua->credentials($req->uri->host_port, "libwww-perl-digest", "ok 23", "xyzzy");
    $res = $ua->request($req);
    #print STDERR $res->as_string;
    ok($res->is_success, 'digest auth: is success');

    # Then illegal credentials
    $ua->credentials($req->uri->host_port, "libwww-perl-digest", "user2", "passwd");
    $res = $ua->request($req);
    is($res->code, 401, 'digest auth: response code 401');
}


{ # proxy
    $ua->proxy(ftp => $base);
    my $req = HTTP::Request->new(GET => "ftp://ftp.perl.com/proxy");
    my $res = $ua->request($req);
    #print $res->as_string;
    ok($res->is_success, 'proxy: is success');
}

{ # post form
    my $req = HTTP::Request->new(POST => url("/echo/foo", $base));
    $req->content_type("application/x-www-form-urlencoded");
    $req->content("foo=bar&bar=test");
    my $res = $ua->request($req);
    #print $res->as_string;

    my $content = $res->content;
    ok($res->is_success, 'post form: is success');
    like($content, qr/^Content-Length:\s*16$/mi, 'post form: header length');
    like($content, qr/^Content-Type:\s*application\/x-www-form-urlencoded$/mi, 'post form: header content type');
    like($content, qr/^foo=bar&bar=test$/m, 'post form: query string');

    $req = HTTP::Request->new(POST => url("/echo/foo", $base));
    $req->content_type("multipart/form-data");
    $req->add_part(HTTP::Message->new(["Content-Type" => "text/plain"], "Hi\n"));
    $req->add_part(HTTP::Message->new(["Content-Type" => "text/plain"], "there\n"));
    $res = $ua->request($req);
    #print $res->as_string;
    ok($res->is_success, 'post form: is success');
    like($res->content, qr/^Content-Type: multipart\/form-data; boundary=/m, 'post form: content multipart');
}

{ # partial
    my $req = HTTP::Request->new(  GET => url("/partial", $base) );
    my $res = $ua->request($req);
    ok($res->is_success, 'partial: is success'); # "a 206 response is considered successful"

    $ua->max_size(3);
    $req = HTTP::Request->new(  GET => url("/partial", $base) );
    $res = $ua->request($req);
    ok($res->is_success, 'partial: is success'); # "a 206 response is considered successful"
    # Put max_size back how we found it.
    $ua->max_size(undef);
    # Client-Aborted is returned when max_size is given
    like($res->as_string, qr/Client-Aborted: max_size/, 'partial: aborted');
}


{ # terminating
    my $req = HTTP::Request->new(GET => url("/quit", $base));
    my $res = $ua->request($req);

    is($res->code, 503, 'terminating: response code is 503');
    like($res->content, qr/Bye, bye/, 'terminating: content bye bye');
}

done_testing();
