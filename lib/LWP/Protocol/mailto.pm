#
# $Id: mailto.pm,v 1.7.2.1 1998/10/12 10:54:49 aas Exp $
#
# This module implements the mailto protocol.  It is just a simple
# frontend to the Unix sendmail program.  This module should probably
# have been built using the Mail::Send module.

package LWP::Protocol::mailto;

require LWP::Protocol;
require HTTP::Request;
require HTTP::Response;
require HTTP::Status;

use Carp;
use strict;
use vars qw(@ISA $SENDMAIL);

@ISA = qw(LWP::Protocol);

$SENDMAIL ||= "/usr/lib/sendmail";


sub request
{
    my($self, $request, $proxy, $arg, $size) = @_;

    # check proxy
    if (defined $proxy)
    {
	return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				  'You can not proxy with mail';
    }

    # check method
    my $method = $request->method;

    if ($method ne 'POST') {
	return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'mailto:' URLs";
    }

    # check url
    my $url = $request->url;

    my $scheme = $url->scheme;
    if ($scheme ne 'mailto') {
	return new HTTP::Response &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				  "LWP::file::request called for '$scheme'";
    }
    unless (-x $SENDMAIL) {
	return new HTTP::Response &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				  "You don't have $SENDMAIL";
    }

    open(SENDMAIL, "| $SENDMAIL -oi -t") or
	return new HTTP::Response &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				  "Can't run $SENDMAIL: $!";

    $request = $request->clone;  # we modify a copy
    my @h = $url->headers;  # URL headers override those in the request
    while (@h) {
	my $k = shift @h;
	my $v = shift @h;
	next unless defined $v;
	if (lc($k) eq "body") {
	    $request->content($v);
	} else {
	    $request->push_header($k => $v);
	}
    }

    print SENDMAIL $request->headers_as_string;
    print SENDMAIL "\n";
    my $content = $request->content;
    if (defined $content) {
	my $contRef = ref($content) ? $content : \$content;
	if (ref($contRef) eq 'SCALAR') {
	    print SENDMAIL $$contRef;
	} elsif (ref($contRef) eq 'CODE') {
	    # Callback provides data
	    my $d;
	    while (length($d = &$contRef)) {
		print SENDMAIL $d;
	    }
	}
    }
    unless (close(SENDMAIL)) {
	my $err = $! ? "$!" : "Exit status $?";
	return HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				   "$SENDMAIL: $err");
    }

    my $response = HTTP::Response->new(&HTTP::Status::RC_ACCEPTED,
				       "Mail accepted");
    $response->header('Content-Type', 'text/plain');
    $response->header('Server' => $SENDMAIL);
    my $to = $request->header("To");
    $response->content("Message sent to <$to>\n");

    return $response;
}

1;
