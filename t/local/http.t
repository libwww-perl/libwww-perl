use FindBin qw($Bin);
if ($^O eq "MacOS") {
    print "1..0\n";
    exit(0);
}

if (0 != system($^X, "$Bin/../../talk-to-ourself")) {
    print "1..0 # Skipped: Can't talk to ourself (misconfigured system)\n";
    exit;
}

delete $ENV{PERL_LWP_ENV_PROXY};

$| = 1; # autoflush

require IO::Socket;  # make sure this work before we try to make a HTTP::Daemon

# First we make ourself a daemon in another process
my $D = shift || '';
if ($D eq 'daemon') {

    require HTTP::Daemon;

    my $d = HTTP::Daemon->new(Timeout => 10);

    print "Please to meet you at: <URL:", $d->url, ">\n";
    open(STDOUT, $^O eq 'VMS'? ">nl: " : ">/dev/null");

    while ($c = $d->accept) {
	$r = $c->get_request;
	if ($r) {
	    my $p = ($r->uri->path_segments)[1];
	    my $func = lc("httpd_" . $r->method . "_$p");
	    if (defined &$func) {
		&$func($c, $r);
	    }
	    else {
		$c->send_error(404);
	    }
	}
	$c = undef;  # close connection
    }
    print STDERR "HTTP Server terminated\n";
    exit;
}
else {
    use Config;
    my $perl = $Config{'perlpath'};
    $perl = $^X if $^O eq 'VMS' or -x $^X and $^X =~ m,^([a-z]:)?/,i;
    open(DAEMON, "$perl $0 daemon |") or die "Can't exec daemon: $!";
}

use Test::More;
plan tests => 63;

my $greeting = <DAEMON>;
$greeting =~ /(<[^>]+>)/;

require URI;
my $base = URI->new($1);
sub url {
   my $u = URI->new(@_);
   $u = $u->abs($_[1]) if @_ > 1;
   $u->as_string;
}

print "Will access HTTP server at $base\n";

require LWP::UserAgent;
require HTTP::Request;
$ua = new LWP::UserAgent;
$ua->agent("Mozilla/0.01 " . $ua->agent);
$ua->from('gisle@aas.no');

#----------------------------------------------------------------
print "Bad request...\n";
$req = new HTTP::Request GET => url("/not_found", $base);
$req->header(X_Foo => "Bar");
$res = $ua->request($req);

ok($res->is_error, 'is_error');
is($res->code, 404, 'response code 404');
like($res->message, qr/not\s+found/i, '404 message');
# we also expect a few headers
ok($res->server);
ok($res->date);

#----------------------------------------------------------------
print "Simple echo...\n";
sub httpd_get_echo
{
    my($c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: message/http\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}

$req = new HTTP::Request GET => url("/echo/path_info?query", $base);
$req->push_header(Accept => 'text/html');
$req->push_header(Accept => 'text/plain; q=0.9');
$req->push_header(Accept => 'image/*');
$req->push_header(':foo_bar' => 1);
$req->if_modified_since(time - 300);
$req->header(Long_text => 'This is a very long header line
which is broken between
more than one line.');
$req->header(X_Foo => "Bar");

$res = $ua->request($req);
#print $res->as_string;

ok($res->is_success);
is($res->code, 200, 'status code 200');
is($res->message, "OK", 'message OK');

$_ = $res->content;
@accept = /^Accept:\s*(.*)/mg;

like($_, qr/^From:\s*gisle\@aas\.no\n/m);
like($_, qr/^Host:/m);
is(@accept, 3, '3 items in accept');
like($_, qr/^Accept:\s*text\/html/m);
like($_, qr/^Accept:\s*text\/plain/m);
like($_, qr/^Accept:\s*image\/\*/m);
like($_, qr/^If-Modified-Since:\s*\w{3},\s+\d+/m);
like($_, qr/^Long-Text:\s*This.*broken between/m);
like($_, qr/^Foo-Bar:\s*1\n/m);
like($_, qr/^X-Foo:\s*Bar\n/m);
like($_, qr/^User-Agent:\s*Mozilla\/0.01/m);

# Try it with the higher level 'get' interface
$res = $ua->get(url("/echo/path_info?query", $base),
    Accept => 'text/html',
    Accept => 'text/plain; q=0.9',
    Accept => 'image/*',
    X_Foo => "Bar",
);
#$res->dump;
is($res->code, 200, 'response code 200');

#----------------------------------------------------------------
print "UserAgent->put...\n";
sub httpd_put_echo
{
    my($c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: message/http\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}
ok($res->content, qr/^From: gisle\@aas.no$/m);
# Try it with the higher level 'get' interface
$res = $ua->put(url("/echo/path_info?query", $base),
    Accept => 'text/html',
    Accept => 'text/plain; q=0.9',
    Accept => 'image/*',
    X_Foo => "Bar",
);
#$res->dump;
is($res->code, 200, 'response code 200');
ok($res->content, qr/^From: gisle\@aas.no$/m);

#----------------------------------------------------------------
print "UserAgent->delete...\n";
sub httpd_delete_echo
{
    my($c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: message/http\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}
ok($res->content, qr/^From: gisle\@aas.no$/m);
# Try it with the higher level 'get' interface
$res = $ua->delete(url("/echo/path_info?query", $base),
    Accept => 'text/html',
    Accept => 'text/plain; q=0.9',
    Accept => 'image/*',
    X_Foo => "Bar",
);
#$res->dump;
is($res->code, 200, 'response code 200');
ok($res->content, qr/^From: gisle\@aas.no$/m);

#----------------------------------------------------------------
print "Send file...\n";

my $file = "test-$$.html";
open(FILE, ">$file") or die "Can't create $file: $!";
binmode FILE or die "Can't binmode $file: $!";
print FILE <<EOT;
<html><title>En prøve</title>
<h1>Dette er en testfil</h1>
Jeg vet ikke hvor stor fila behøver å være heller, men dette
er sikkert nok i massevis.
EOT
close(FILE);

sub httpd_get_file
{
    my($c, $r) = @_;
    my %form = $r->uri->query_form;
    my $file = $form{'name'};
    $c->send_file_response($file);
    unlink($file) if $file =~ /^test-/;
}

$req = new HTTP::Request GET => url("/file?name=$file", $base);
$res = $ua->request($req);
#print $res->as_string;

ok($res->is_success);
ok($res->content_type, 'text/html');
is($res->content_length, 147, '147 content length');
ok($res->title, 'En prøve');
ok($res->content, qr/å være/);

# A second try on the same file, should fail because we unlink it
$res = $ua->request($req);
#print $res->as_string;
ok($res->is_error);
is($res->code, 404, 'response code 404');   # not found

# Then try to list current directory
$req = new HTTP::Request GET => url("/file?name=.", $base);
$res = $ua->request($req);
#print $res->as_string;
is($res->code, 501, 'response code 501');   # NYI


#----------------------------------------------------------------
print "Check redirect...\n";
sub httpd_get_redirect
{
   my($c) = @_;
   $c->send_redirect("/echo/redirect");
}

$req = new HTTP::Request GET => url("/redirect/foo", $base);
$res = $ua->request($req);
#print $res->as_string;

ok($res->is_success);
ok($res->content, qr|/echo/redirect|);
ok($res->previous->is_redirect);
is($res->previous->code, 301, 'response code 301');

# Let's test a redirect loop too
sub httpd_get_redirect2 { shift->send_redirect("/redirect3/") }
sub httpd_get_redirect3 { shift->send_redirect("/redirect2/") }

$req->uri(url("/redirect2", $base));
$ua->max_redirect(5);
$res = $ua->request($req);
#print $res->as_string;
ok($res->is_redirect);
ok($res->header("Client-Warning"), qr/loop detected/i);
is($res->redirects, 5, '5 max redirects');

$ua->max_redirect(0);
$res = $ua->request($req);
is($res->previous, undef, 'undefined previous');
is($res->redirects, 0, 'zero redirects');
$ua->max_redirect(5);

#----------------------------------------------------------------
print "Check basic authorization...\n";
sub httpd_get_basic
{
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

{
   package MyUA; @ISA=qw(LWP::UserAgent);
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
$req = new HTTP::Request GET => url("/basic", $base);
$res = MyUA->new->request($req);
#print $res->as_string;

ok($res->is_success);
#print $res->content;

# Let's try with a $ua that does not pass out credentials
$res = $ua->request($req);
is($res->code, 401, 'respone code 401');

# Let's try to set credentials for this realm
$ua->credentials($req->uri->host_port, "libwww-perl", "ok 12", "xyzzy");
$res = $ua->request($req);
ok($res->is_success);

# Then illegal credentials
$ua->credentials($req->uri->host_port, "libwww-perl", "user", "passwd");
$res = $ua->request($req);
is($res->code, 401, 'response code 401');


#----------------------------------------------------------------
print "Check digest authorization...\n";
sub httpd_get_digest
{
	my($c, $r) = @_;
#    print STDERR $r->as_string;
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

{
	package MyUA2; @ISA=qw(LWP::UserAgent);
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
$req = new HTTP::Request GET => url("/digest", $base);
$res = MyUA2->new->request($req);
#print STDERR $res->as_string;

ok($res->is_success);
#print $res->content;

# Let's try with a $ua that does not pass out credentials
$ua->{basic_authentication}=undef;
$res = $ua->request($req);
is($res->code, 401, 'respone code 401');

# Let's try to set credentials for this realm
$ua->credentials($req->uri->host_port, "libwww-perl-digest", "ok 23", "xyzzy");
$res = $ua->request($req);
#print STDERR $res->as_string;
ok($res->is_success);

# Then illegal credentials
$ua->credentials($req->uri->host_port, "libwww-perl-digest", "user2", "passwd");
$res = $ua->request($req);
is($res->code, 401, 'response code 401');



#----------------------------------------------------------------
print "Check proxy...\n";
sub httpd_get_proxy
{
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

$ua->proxy(ftp => $base);
$req = new HTTP::Request GET => "ftp://ftp.perl.com/proxy";
$res = $ua->request($req);
#print $res->as_string;
ok($res->is_success);

#----------------------------------------------------------------
print "Check POSTing...\n";
sub httpd_post_echo
{
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

$req = new HTTP::Request POST => url("/echo/foo", $base);
$req->content_type("application/x-www-form-urlencoded");
$req->content("foo=bar&bar=test");
$res = $ua->request($req);
#print $res->as_string;

$_ = $res->content;
ok($res->is_success);
ok($_, qr/^Content-Length:\s*16$/mi);
ok($_, qr/^Content-Type:\s*application\/x-www-form-urlencoded$/mi);
ok($_, qr/^foo=bar&bar=test$/m);

$req = HTTP::Request->new(POST => url("/echo/foo", $base));
$req->content_type("multipart/form-data");
$req->add_part(HTTP::Message->new(["Content-Type" => "text/plain"], "Hi\n"));
$req->add_part(HTTP::Message->new(["Content-Type" => "text/plain"], "there\n"));
$res = $ua->request($req);
#print $res->as_string;
ok($res->is_success);
ok($res->content =~ /^Content-Type: multipart\/form-data; boundary=/m);

#----------------------------------------------------------------
print "Check partial content response...\n";
sub httpd_get_partial
{
   my($c) = @_;
    $c->send_basic_header(206);
    print $c "Content-Type: image/jpeg\015\012";
    $c->send_crlf;
    print $c "some fake JPEG content";

}

{
    $req = HTTP::Request->new(  GET => url("/partial", $base) );
    $res = $ua->request($req);
    ok($res->is_success); # "a 206 response is considered successful"
}
{
    $ua->max_size(3);
    $req = HTTP::Request->new(  GET => url("/partial", $base) );
    $res = $ua->request($req);
    ok($res->is_success); # "a 206 response is considered successful"
    # Put max_size back how we found it. 
    $ua->max_size(undef);
    ok($res->as_string, qr/Client-Aborted: max_size/); # Client-Aborted is returned when max_size is given
}


#----------------------------------------------------------------
print "Terminating server...\n";
sub httpd_get_quit
{
    my($c) = @_;
    $c->send_error(503, "Bye, bye");
    exit;  # terminate HTTP server
}

$req = new HTTP::Request GET => url("/quit", $base);
$res = $ua->request($req);

is($res->code, 503, 'response code is 503');
ok($res->content, qr/Bye, bye/);
