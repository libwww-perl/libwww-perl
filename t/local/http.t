$| = 1; # autoflush

# First we make ourself a daemon in another process

unless (open(DAEMON, "-|")) {

    require HTTP::Daemon;

    my $d = new HTTP::Daemon Timeout => 10;

    print "Please to meet you at: <URL:", $d->url, ">\n";
    open(STDOUT, ">/dev/null");

    while ($c = $d->accept) {
	$r = $c->get_request;
	if ($r) {
	    my $p = ($r->url->path_components)[1];
	    my $func = lc("httpd_" . $r->method . "_$p");
	    print STDERR "$func\n";
	    if (defined &$func) {
		&$func($c, $r);
	    } else {
		$c->send_error(403);
	    }
	}
	$c = undef;  # close connection
    }
    print STDERR "HTTP Server terminated\n";
    exit;
}

print "1..10\n";


$greating = <DAEMON>;
$greating =~ /(<[^>]+>)/;

require URI::URL;
URI::URL->import;
$base = new URI::URL $1;

print "Will access HTTP server at $base\n";

require LWP::UserAgent;
require HTTP::Request;

$ua = new LWP::UserAgent;

$req = new HTTP::Request GET => url("/test1", $base);
$req->header(X_Foo => "Bar");

$res = $ua->request($req);
print $res->as_string;



$req = new HTTP::Request GET => url("/quit", $base);
$res = $ua->request($req);
print $res->as_string;

sub httpd_get_quit {
    print STDERR "Quiting\n";
    exit;
}

