#
# $Id: http.pm,v 1.38 1998/01/20 14:22:44 aas Exp $

package LWP::Protocol::http;

require LWP::Debug;
require HTTP::Response;
require HTTP::Status;
require IO::Socket;
require IO::Select;

require LWP::Protocol;
@ISA = qw(LWP::Protocol);

use strict;
my $CRLF         = "\015\012";     # how lines should be terminated;
				   # "\r\n" is not correct on all systems, for
				   # instance MacPerl defines it to "\012\015"

sub _new_socket
{
    my($self, $host, $port, $timeout) = @_;

    local($^W) = 0;  # IO::Socket::INET can be noisy
    my $sock = IO::Socket::INET->new(PeerAddr => $host,
				     PeerPort => $port,
				     Proto    => 'tcp',
				     Timeout  => $timeout,
				    );
    unless ($sock) {
	# IO::Socket::INET leaves additional error messages in $@
	$@ =~ s/^.*?: //;
	die "Can't connect to $host:$port ($@)";
    }
    $sock;
}


sub _check_sock
{
    #my($self, $req, $sock) = @_;
}

sub _get_sock_info
{
    my($self, $res, $sock) = @_;
    $res->header("Client-Peer" =>
		 $sock->peerhost . ":" . $sock->peerport);
}


sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    LWP::Debug::trace('()');

    $size ||= 4096;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
	return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'http:' URLs";
    }

    my $url = $request->url;
    my($host, $port, $fullpath);

    # Check if we're proxy'ing
    if (defined $proxy) {
	# $proxy is an URL to an HTTP server which will proxy this request
	$host = $proxy->host;
	$port = $proxy->port;
	$fullpath = $url->as_string;
    }
    else {
	$host = $url->host;
	$port = $url->port;
	$fullpath = $url->full_path;
    }

    # connect to remote site
    my $socket = $self->_new_socket($host, $port, $timeout);
    $self->_check_sock($request, $socket);
	    
    my $sel = IO::Select->new($socket) if $timeout;

    my $request_line = "$method $fullpath HTTP/1.0$CRLF";

    # If we're sending content we *have* to specify a content length
    # otherwise the server won't know a messagebody is coming.
    my $content = $request->content;

    # All this mess because we want to support content as both scalar,
    # ref to scalar and ref to code.
    my $contRef;
    if (defined $content) {
	$contRef = ref($content) ? $content : \$content;
	if (ref($contRef) eq 'SCALAR') {
	    $request->header('Content-Length' => length $$contRef)
	        if length $$contRef;
	} elsif (ref($contRef) eq 'CODE') {
	    die 'No Content-Length header for request with code content'
	      unless $request->header('Content-Length');
	} else {
	    my $type = ref($contRef);
	    die "Illegal content type ($type) in request";
	}
    }

    # HTTP/1.1 will require us to send the 'Host' header, so we might
    # as well start now.
    {
	my $host = $url->netloc;
	$host =~ s/^([^\@]*)\@//;  # get rid of potential "user:pass@"
	$request->header('Host' => $host);

	# add authorization header if we need them
	if (defined($1) && not $request->header('Authorization')) {
	    $request->authorization_basic($url->user, $url->password);
	}
    }

    # we always assume that we are writeable
    my $buf = $request_line . $request->headers_as_string($CRLF) . $CRLF;
    {
	die "write timeout" if $timeout && !$sel->can_write($timeout);
	my $n = $socket->syswrite($buf, length($buf));
	die $! unless defined($n);
	die "short write" unless $n == length($buf);
	LWP::Debug::conns($buf);
    }
    if (defined $content) {
	if (ref($contRef) eq 'CODE') {
	    while ( ($buf = &$contRef()), defined($buf) && length($buf)) {
		die "write timeout" if $timeout && !$sel->can_write($timeout);
		my $n = $socket->syswrite($buf, length($buf));
		die $! unless defined($n);
		die "short write" unless $n == length($buf);
		LWP::Debug::conns($buf);
	    }
	} else {
	    die "write timeout" if $timeout && !$sel->can_write($timeout);
	    my $n = $socket->syswrite($$contRef, length($$contRef));
	    die $! unless defined($n);
	    die "short write" unless $n == length($$contRef);
	    LWP::Debug::conns($buf);
	}
    }

    # read response line from server
    LWP::Debug::debug('reading response');

    my $response;
    $buf = '';

    # Inside this loop we will read the response line and all headers
    # found in the response.
    while (1) {
	{
	    die "read timeout" if $timeout && !$sel->can_read($timeout);
	    my $n = $socket->sysread($buf, $size, length($buf));
	    die $! unless defined($n);
	    die "unexpected EOF before status line seen" unless $n;
	    LWP::Debug::conns($buf);
	}
	if ($buf =~ s/^(HTTP\/\d+\.\d+)[ \t]+(\d+)[ \t]*([^\012]*)\012//) {
	    # HTTP/1.0 response or better
	    my($ver,$code,$msg) = ($1, $2, $3);
	    $msg =~ s/\015$//;
	    LWP::Debug::debug("$ver $code $msg");
	    $response = HTTP::Response->new($code, $msg);
	    $response->protocol($ver);

	    # ensure that we have read all headers.  The headers will be
	    # terminated by two blank lines
	    while ($buf !~ /\015?\012\015?\012/) {
		# must read more if we can...
		LWP::Debug::debug("need more header data");
		die "read timeout" if $timeout && !$sel->can_read($timeout);
		my $n = $socket->sysread($buf, $size, length($buf));
		die $! unless defined($n);
		die "unexpected EOF before all headers seen" unless $n;
		#LWP::Debug::conns($buf);
	    }

	    # now we start parsing the headers.  The strategy is to
	    # remove one line at a time from the beginning of the header
	    # buffer ($res).
	    my($key, $val);
	    while ($buf =~ s/([^\012]*)\012//) {
		my $line = $1;

		# if we need to restore as content when illegal headers
		# are found.
		my $save = "$line\012"; 

		$line =~ s/\015$//;
		last unless length $line;

		if ($line =~ /^([a-zA-Z0-9_\-]+)\s*:\s*(.*)/) {
		    $response->push_header($key, $val) if $key;
		    ($key, $val) = ($1, $2);
		} elsif ($line =~ /^\s+(.*)/) {
		    unless ($key) {
			$response->header("Client-Warning" =>
					 => "Illegal continuation header");
			$buf = "$save$buf";
			last;
		    }
		    $val .= " $1";
		} else {
		    $response->header("Client-Warning" =>
				      "Illegal header '$line'");
		    $buf = "$save$buf";
		    last;
		}
	    }
	    $response->push_header($key, $val) if $key;
	    last;

	} elsif ((length($buf) >= 5 and $buf !~ /^HTTP\//) or
		 $buf =~ /\012/ ) {
	    # HTTP/0.9 or worse
	    LWP::Debug::debug("HTTP/0.9 assume OK");
	    $response = HTTP::Response->new(&HTTP::Status::RC_OK, "OK");
	    $response->protocol('HTTP/0.9');
	    last;

	} else {
	    # need more data
	    LWP::Debug::debug("need more status line data");
	}
    };
    $response->request($request);
    $self->_get_sock_info($response, $socket);


    my $usebuf = length($buf) > 0;
    $response = $self->collect($arg, $response, sub {
        if ($usebuf) {
	    $usebuf = 0;
	    return \$buf;
	}
	die "read timeout" if $timeout && !$sel->can_read($timeout);
	my $n = $socket->sysread($buf, $size);
	die $! unless defined($n);
	#LWP::Debug::conns($buf);
	return \$buf;
	} );

    $socket->close;

    $response;
}

1;
