#
# $Id: http.pm,v 1.25 1996/11/11 17:46:39 aas Exp $

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

# "" = No content in request, "C" = Needs content in request
my %allowedMethods = (
    OPTIONS    => "",
    GET        => "",
    HEAD       => "",
    POST       => "C",
    PUT        => "C",
    PATCH      => "C",
    COPY       => "",
    MOVE       => "",
    DELETE     => "",
    LINK       => "",
    UNLINK     => "",
    TRACE      => "",
    WRAPPED    => "C",
);


sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    LWP::Debug::trace('()');

    $size = 4096 unless $size;

    # check method
    my $method = $request->method;
    unless (defined $allowedMethods{$method}) {
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
    my $socket = new LWP::Socket;
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

    my $line;
    my $result = $socket->read_until("\015?\012", \$line, undef, $timeout);

    my $response;

    # parse response header
    if ($line =~ /^HTTP\/(\d+\.\d+)\s+(\d+)\s+(.*)/) { # HTTP/1.0 or better
	my $ver = $1;
	LWP::Debug::debug("HTTP/$ver server");

	$response = HTTP::Response->new($2, $3);

	LWP::Debug::debug('reading rest of response header');
	my $header = '';
	my $result = $socket->read_until("\015?\012\015?\012", \$header,
					 undef, $timeout);

	# now entire header is read, parse it
	LWP::Debug::debug('parsing response header');
	my($key, $val);
	for (split(/\015?\012/, $header)) {
	    if (/^(\S+?):\s*(.*)$/) {
		$response->push_header($key, $val) if $key;
		($key, $val) = ($1, $2);
	    } elsif (/\s+(.*)/) {
		next unless $key;
		$val .= " $1";
	    }
	}
	$response->push_header($key, $val) if $key;
    } else {
	# HTTP/0.9 or worse. Assume OK
	LWP::Debug::debug('HTTP/0.9 server');
	$response = HTTP::Response->new(&HTTP::Status::RC_OK,
					'HTTP 0.9 server');
	#XXX: Unfortunately, we have lost the line ending sequence.  So
	# we just guess that it is '\n'.  This will not always be correct.
	$socket->pushback("$line\n");
    }
    $response->request($request);

    # need to read content
    alarm($timeout) if $self->use_alarm and $timeout;

    LWP::Debug::debug('Reading content');
    $response = $self->collect($arg, $response, sub {
	LWP::Debug::debug('collecting');
	my $content = '';
	my $result = $socket->read(\$content, $size, $timeout);
	return \$content;
	} );
    $socket = undef;  # close it

    $response;
}

1;
