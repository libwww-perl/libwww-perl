#
# $Id: http.pm,v 1.32 1997/08/05 14:24:21 aas Exp $

package LWP::Protocol::http;

require LWP::Debug;
require LWP::Protocol;
require LWP::Socket;
require HTTP::Request;
require HTTP::Response;
require HTTP::Status;

use Carp ();

@ISA = qw(LWP::Protocol);

use strict;

my $httpversion  = 'HTTP/1.0';     # for requests
my $endl         = "\015\012";     # how lines should be terminated;
				   # "\r\n" is not correct on all systems, for
				   # instance MacPerl defines it to "\012\015"

sub _new_socket
{
    LWP::Socket->new;
}

sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    LWP::Debug::trace('()');

    $size ||= 4096;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!#\$%&'*+\-.^`|~]+$/) {     # HTTP token
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

    alarm($timeout) if $self->use_alarm and $timeout;

    # connect to remote site
    my $socket = $self->_new_socket();
    $socket->connect($host, $port);

    my $request_line = "$method $fullpath $httpversion$endl";

    # If we're sending content we *have* to specify a content length
    # otherwise the server won't know a messagebody is coming.

    my $content = $request->content;

    # All this mess because we want to support content as both scalar,
    # ref to scalar and ref to code.
    my $contRef;
    if (defined $content){
	$contRef = ref($content) ? $content : \$content;
	if (ref($contRef) eq 'SCALAR') {
	    $request->header('Content-Length', length $$contRef)
	      if length $$contRef;
	} elsif (ref($contRef) eq 'CODE') {
	    Carp::croak('No Content-Length header for request with content')
	      unless $request->header('Content-Length');
	} else {
	    Carp::croak("Illegal content in request ($content)");
	}
    }

    # HTTP/1.1 will require us to send the 'Host' header, so we might
    # as well start now.
    $request->header('Host', $url->netloc);

    $socket->write($request_line . $request->headers_as_string($endl) . $endl);
    if (defined $content) {
	if (ref($contRef) eq 'CODE') {
	    $socket->write($contRef, $timeout);
	} else {
	    $socket->write($$contRef, $timeout);
	}
    }

    # read response line from server
    LWP::Debug::debug('reading response');

    my $res = "";
    my $buf = "";
    my $response;

    # Inside this loop we will read the response line and all headers
    # found in the response.
    while ($socket->read(\$buf, undef, $timeout)) {
	$res .= $buf;
	if ($res =~ s/^(HTTP\/\d+\.\d+)[ \t]+(\d+)[ \t]*([^\012]*)\012//) {
	    # HTTP/1.0 response or better
	    my($ver,$code,$msg) = ($1, $2, $3);
	    $msg =~ s/\015$//;
	    LWP::Debug::debug("$ver $code $msg");
	    $response = HTTP::Response->new($code, $msg);
	    $response->protocol($ver);

	    # ensure that we have read all headers.  The headers will be
	    # terminated by two blank lines
	    while ($res !~ /\015?\012\015?\012/) {
		# must read more if we can...
		LWP::Debug::debug("need more data for headers");
		last unless $socket->read(\$buf, undef, $timeout);
		$res .= $buf;
	    }

	    # now we start parsing the headers.  The strategy is to
	    # remove one line at a time from the beginning of the header
	    # buffer ($res).
	    my($key, $val);
	    while ($res =~ s/([^\012]*)\012//) {
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
			LWP::Debug::debug("Illegal continuation header");
			$res = "$save$res";
			last;
		    }
		    $val .= " $1";
		} else {
		    LWP::Debug::debug("Illegal header '$line'");
		    $res = "$save$res";
		    last;
		}
	    }
	    $response->push_header($key, $val) if $key;
	    last;

	} elsif ((length($res) >= 5 and $res !~ /^HTTP\//) or
		 $res =~ /\012/ ) {
	    # HTTP/0.9 or worse
	    LWP::Debug::debug("HTTP/0.9 assume OK");
	    $response = HTTP::Response->new(&HTTP::Status::RC_OK, "OK");
	    $response->protocol('HTTP/0.9');
	    last;

	} else {
	    # need more data
	    LWP::Debug::debug("need more data to know which protocol");
	}
    };
    die "Unexpected EOF" unless $response;

    $socket->pushback($res) if length $res;
    $response->request($request);

    # need to read content
    alarm($timeout) if $self->use_alarm and $timeout;

    $response = $self->collect($arg, $response, sub {
	LWP::Debug::debug('Collecting');
	my $content = '';
	my $result = $socket->read(\$content, $size, $timeout);
	return \$content;
	} );
    $socket = undef;  # close it

    $response;
}

1;
