#
# $Id: nntp.pm,v 1.5 1996/07/08 13:37:01 aas Exp $

# Implementation of the Network News Transfer Protocol (RFC 977)
#

package LWP::Protocol::nntp;

require LWP::Protocol;
@ISA = qw(LWP::Protocol);

require LWP::Socket;
require LWP::Debug;

require HTTP::Request;
require HTTP::Response;
use HTTP::Status ();

use strict;
use vars qw($NNTP_SERVER $NNTP_PORT);

$NNTP_SERVER = $ENV{NNTP_SERVER} || "news";
$NNTP_PORT   = 119;


sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;

    LWP::Debug::trace('()');

    $size = 4096 unless $size;

    # Check for proxy
    if (defined $proxy) {
	return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
				   'You can not proxy through NNTP');
    }

    # Check that the scheme is as expected
    my $url = $request->url;
    my $scheme = $url->scheme;
    unless ($scheme eq 'news') {
	return HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				   "LWP::Protocol::nntp::request called for '$scheme'");
    }

    # check for a valid method
    my $method = $request->method;
    unless ($method eq 'GET' || $method eq 'HEAD' || $method eq 'POST') {
	return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
				   'Library does not allow method ' .
				   "$method for 'news:' URLs");
    }

    # extract the identifier and check against posting to an article
    my $groupart = $url->groupart;
    my $is_art = $groupart =~ /@/;

    if ($is_art && $method eq 'POST') {
	return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
				   "Can't post to an article <$groupart>");
    }

    # Create a socket and connect to the NNTP server.  We use our own
    # specialization of the LWP::Socket class.  This new class is defined
    # below.
    my $nntp = new LWP::Protocol::nntp::Socket;  # What an ugly name
    $nntp->connect($NNTP_SERVER, $NNTP_PORT);

    # Check the initial welcome message from the NNTP server
    if ($nntp->response($timeout) != 2) {
	return HTTP::Response->new(&HTTP::Status::RC_SERVICE_UNAVAILABLE,
				   $nntp->message);
    }
    my $response = HTTP::Response->new(&HTTP::Status::RC_OK, "OK");

    my $mess = $nntp->message;
    LWP::Debug::debug($mess);

    # Try to extract server name from greating message.
    # Don't know if this works well for a large class of servers, but
    # this works for our server.
    $mess =~ s/\s+ready\b.*//;
    $mess =~ s/^\S+\s+//;
    $response->header('Server', $mess);

    # First we handle posting of articles
    if ($method eq 'POST') {
	$request->header("Newsgroups", $groupart)
	    unless $request->header("Newsgroups");
	if ($nntp->cmd("POST") != 3) {
	    return HTTP::Response->new(&HTTP::Status::RC_FORBIDDEN,
				       $nntp->message);
	}
	$nntp->write($request->headers_as_string("\015\012") . "\015\012");
	my $content = $request->content;
	$content =~ s/^\./../gm;  # must escape "." at the beginning of lies
	$nntp->write($content);
	$nntp->write("\015\012.\015\012"); 	# Terminate message
	if ($nntp->response != 2) {
	    return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
				       $nntp->message);
	}
	$response->code(&HTTP::Status::RC_ACCEPTED);
	$response->message($nntp->message);
	return $response;
    }

    # The method must be "GET" or "HEAD" by now
    if (!$is_art) {
	if ($nntp->cmd("GROUP $groupart") != 2) {
	    return HTTP::Response->new(&HTTP::Status::RC_NOT_FOUND,
				       $nntp->message);
	}
	return HTTP::Response->new(&HTTP::Status::RC_NOT_IMPLEMENTED,
				   "GET newsgroup not implemented yet");
    }

    # Send command to server to retrieve an article (or just the headers)
    my $cmd = ($method eq 'HEAD' ? 'HEAD' : 'ARTICLE') . " <$groupart>";
    if ($nntp->cmd($cmd, $timeout) != 2) {
	return HTTP::Response->new(&HTTP::Status::RC_NOT_FOUND,
				   $nntp->message);
    }
    LWP::Debug::debug($nntp->message);

    # Must read article data until ".".  Here we just "fake" it using the
    # read_until method.  We should really use the normal read() method
    # so that we are able to handle real big articles much better.
    $nntp->read_until('\015?\012\.\015?\012', \$mess, $size, $timeout);

    my($headers, $body) = split(/(?:\015?\012){2}/, $mess, 2);

    # Parse headers
    my($key, $val);
    for (split(/\015?\012/, $headers)) {
	if (/^(\S+):\s*(.*)/) {
	    $response->push_header($key, $val) if $key;
	    ($key, $val) = ($1, $2);
	} elsif (/^\s+(.*)/) {
	    next unless $key;
	    $val .= $1;
	}
    }
    $response->push_header($key, $val) if $key;

    # Ensure that there is a Content-Type header
    $response->header("Content-Type", "text/plain")
	unless $response->header("Content-Type");

    # Collect the body
    if (defined $body) {
	$body =~ s/\r//g;
	$body =~ s/^\.\././gm;
	$response = $self->collect_once($arg, $response, $body);
    }

    # Say godbye to the server
    $nntp->cmd("QUIT");
    $nntp = undef;

    $response;
}

# Out special NNTP socket class.  This is just like LWP::Sockets, but
# implement a few new methods.
#
#    $sock->cmd("CMD", $timeout);  # Sends command to server and return the
#                                  # first digit of the response code
#
#    $sock->response($timeout);    # Read response line from server and
#                                  # return first digit of the response code.
#
#    $sock->code                   # Return the full response code (last one)
#    $sock->message                # Return response message.
#

package LWP::Protocol::nntp::Socket;
use vars qw(@ISA);
@ISA = qw(LWP::Socket);

sub cmd {
    my($self, $cmd, $timeout) = @_;
    $self->write("$cmd\015\012", $timeout);
    $self->response($timeout);
}


sub response {
    my($self, $timeout) = shift;
    my $resp;
    $self->read_until("\015?\012", \$resp, undef, $timeout);
    $resp =~ s/^(\d{3})\s*//;
    my $code = $1;
    $self->{nntp_message} = $resp;
    $self->{nntp_code} = $code;
    substr($code, 0, 1);
}

sub message { shift->{'nntp_message'}; }
sub code    { shift->{'nntp_code'};    }


package LWP::Protocol::nntp;

1;
