#
# $Id: http.pm,v 1.5 1995/07/14 00:18:16 aas Exp $

package LWP::Protocol::http;

#####################################################################

require LWP::Protocol;
require LWP::Request;
require LWP::Response;
require LWP::Debug;
require LWP::StatusCode;
require LWP::Socket;

use Carp;
use FileHandle;

@ISA = qw(LWP::Protocol);

$httpprotocol = 'http';         # for getservbyname
$httpversion = 'HTTP/1.0';      # for requests

# 0 = Not allowed (same as undefined / !exists)
# 1 = Allowed without content in request
# 2 = Allowed and with content in request
%AllowedMethods = (
    GET        => 1,   
    HEAD       => 1,
    POST       => 2,   
    PUT        => 2,
    DELETE     => 1,   
    LINK       => 1,
    UNLINK     => 1,
    CHECKIN    => 2,
    CHECKOUT   => 1,
    SHOWMETHOD => 1,
);

#####################################################################

# constructor inherited fro LWP::Protocol

sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;

    LWP::Debug::trace("LWP::http::request(" . 
                      (defined $request ? $request : '<undef>') . ', ' .
                      (defined $arg ? $arg : '<undef>') . ', ' .
                      (defined $size ? $size : '<undef>') .')');

    $size = 4096 unless defined $size and $size > 0;

    # check method

    my $method = $request->method;
    unless (exists $AllowedMethods{$method} and
            defined $AllowedMethods{$method} and
            $AllowedMethods{$method} != 0 )
    {
        return new
          LWP::Response(&LWP::StatusCode::RC_BAD_REQUEST,
                        'Library does not allow method ' .
                        "$method for 'http:' URLs");
    }

    # Check if we're proxy'ing
    
    my $url = $request->url;

    my ($host, $port, $fullpath);

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
    $socket = new LWP::Socket;

    alarm($timeout) if $self->useAlarm and defined $timeout;

    $socket->open($host, $port);
    LWP::Debug::debug('connected');

    my $request_line = "$method $fullpath $httpversion\r\n";
    LWP::Debug::debug("request line: $request_line");

    # If we're sending content we *have* to specify
    # a content length otherwise the server won't
    # know a messagebody is coming.

    my $content = $request->content;
    if (defined $content){
        $request->header('Content-Length', length($content));
    }
    my $senddata = $request_line . $request->headerAsString("\r\n") . "\r\n";
    if (defined $content) {
        $senddata .= $content;
    }

    LWP::Debug::conns("sending request: $senddata");
    
    $socket->write($senddata);

    # read response line from server
    LWP::Debug::debugl('reading response');

    my $line;
    my $delim = "\r?\n";
    my $result = $socket->readUntil($delim, \$line, $size, $timeout);

    LWP::Debug::conns("Received response: $line");

    # parse response header
    my $response;
    
    if ($line =~ m:^HTTP/(\d+\.\d+)\s+(\d+)\s(.*)$:) # HTTP/1.0 or better
    {
        # XXX need to check protocol version
        LWP::Debug::debug('HTTP/1.0 server');

        $response = new LWP::Response($2, $3);
        
        LWP::Debug::debug('reading response header');

        my $header = '';
        my $delim = "\r?\n\r?\n";
        my $result = $socket->readUntil($delim, \$header, $size, $timeout);

        @headerlines = split("\r?\n", $header);

        # now entire header is read, parse it
        LWP::Debug::debug('parsing response header');

        my %parsedheaders;
        my($lastkey, $lastval) = ('', '');
        for (@headerlines) {
            if (/^(\S+?):\s*(.*)$/) {
                my ($key, $val) = ($1, $2);
                if ($lastkey and $lastval) {
                    LWP::Debug::debug("  $lastkey => $lastval");
                    $response->header($lastkey, $lastval);
                }
                $lastkey = $key;
                $lastval = $val;
            } elsif (/\s+(.*)/) {
                croak('Unexpected header continuation')
                    unless defined $lastval;
                $lastval .= " $1";
            } else {
                croak("Illegal header '$_'");
            }
        }
        if ($lastkey and $lastval) {
            LWP::Debug::debug("  $lastkey => $lastval");
            $response->header($lastkey, $lastval);
        }
    } else {
        # HTTP/0.9 or worse. Assume OK
        LWP::Debug::debug('HTTP/0.9 server');

        $response = new LWP::Response(&LWP::StatusCode::RC_OK);
    }

    # need to read content
    LWP::Debug::debug('Reading content');

    alarm($timeout) if $self->useAlarm and defined $timeout;
     
    $response = $self->collect($arg, $response, sub { 
        LWP::Debug::debug('collecting');
        my $content = '';
        my $result = $socket->readUntil(undef, \$content, $size, $timeout);
        LWP::Debug::debug("collected: $content");
        return \$content;
        } );

    $socket->close;

    $response;
}

#####################################################################

1;
