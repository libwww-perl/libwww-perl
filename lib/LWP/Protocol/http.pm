#
# $Id: http.pm,v 1.16 1995/09/04 20:43:19 aas Exp $

package LWP::Protocol::http;

require LWP::Debug;
require LWP::Protocol;
require LWP::Socket;
require HTTP::Request;
require HTTP::Response;
require HTTP::Status;

use Carp;
use FileHandle;

@ISA = qw(LWP::Protocol);

my $httpversion  = 'HTTP/1.0';     # for requests
my $endl         = "\015\012";     # how lines should be terminated;
                                   # "\r\n" is not correct on all systems, for
                                   # instance MacPerl defines it to "\012\015"

# "" = No content in request, "C" = Needs content in request
%allowedMethods = (
    GET        => "",   
    HEAD       => "",
    POST       => "C",   
    PUT        => "C",
    DELETE     => "",   
    LINK       => "",
    UNLINK     => "",
    CHECKIN    => "C",
    CHECKOUT   => "",
    SHOWMETHOD => "",
);


sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;

    LWP::Debug::trace('LWP::http::request(' . 
                      (defined $request ? $request : '<undef>') . ', ' .
                      (defined $arg ? $arg : '<undef>') . ', ' .
                      (defined $size ? $size : '<undef>') .')');

    $size = 4096 unless defined $size and $size > 0;

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
        # $proxy is an HTTP server which will proxy this request
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
    my $socket = new LWP::Socket;

    alarm($timeout) if $self->useAlarm and defined $timeout;

    $socket->connect($host, $port);

    my $request_line = "$method $fullpath $httpversion$endl";
    LWP::Debug::debug("request line: $request_line");

    # If we're sending content we *have* to specify a content length
    # otherwise the server won't know a messagebody is coming.

    my $content = $request->content;

    # All this mess because we want to support content as both scalar,
    # ref to scalar and ref to code.
    my $contRef;
    if (defined $content){
	$contRef = ref($content) ? $content : \$content;
	if (ref($contRef) eq 'SCALAR') {
	    $request->header('Content-Length', length $$contRef);
	} elsif (ref($contRef) eq 'CODE') {
	    croak('No Content-Length header for request with content')
	      unless $request->header('Content-Length');
	} else {
	    croak "Illegal content in request ($content)";
	}
    }

    $socket->write($request_line . $request->headerAsString($endl) . $endl);
    if (defined $content) { 
	if (ref($contRef) eq 'CODE') {
	    $socket->write($contRef, $timeout);
	} else {
	    $socket->write($$contRef, $timeout);
	}
      }

    # read response line from server
    LWP::Debug::debugl('reading response');

    my $line;
    my $delim = "\015?\012";
    my $result = $socket->readUntil($delim, \$line, undef, $timeout);

    my $response;
    
    # parse response header
    if ($line =~ /^HTTP\/(\d+\.\d+)\s+(\d+)\s+(.*)/) { # HTTP/1.0 or better

	my $ver = $1;
        LWP::Debug::debug('HTTP/$ver server');

        $response = new HTTP::Response($2, $3);
        
        LWP::Debug::debug('reading rest of response header');
        my $header = '';
        my $delim = "\015?\012\015?\012";
        my $result = $socket->readUntil($delim, \$header, undef, $timeout);

        @headerlines = split(/\015?\012/, $header);

        # now entire header is read, parse it
        LWP::Debug::debug('parsing response header');

        my %parsedheaders;
        my($lastkey, $lastval) = ('', '');
        for (@headerlines) {
            if (/^(\S+?):\s*(.*)$/) {
                my ($key, $val) = ($1, $2);
                if (length $lastkey and length $lastval) {
                    $response->pushHeader($lastkey, $lastval);
                }
                $lastkey = $key;
                $lastval = $val;
            } elsif (/\s+(.*)/) {
                $lastval .= " $1";
            } else {
                warn("Illegal header '$_'");
            }
        }
        if (length $lastkey and length $lastval) {
            $response->pushHeader($lastkey, $lastval);
        }
    } else {
        # HTTP/0.9 or worse. Assume OK
        LWP::Debug::debug('HTTP/0.9 server');
        $response = new HTTP::Response &HTTP::Status::RC_OK,
                                      'HTTP 0.9 server';
	$socket->pushback("$line\n");  #XXX: '\n' is not always correct
    }

    # need to read content
    alarm($timeout) if $self->useAlarm and defined $timeout;
     
    LWP::Debug::debug('Reading content');
    $response = $self->collect($arg, $response, sub { 
        LWP::Debug::debug('collecting');
        my $content = '';
        my $result = $socket->read(\$content, $size, $timeout);
        LWP::Debug::debug("collected: $content");
        return \$content;
        } );

    $socket = undef;  # close it

    $response;
}


1;
