#
# $Id: gopher.pm,v 1.1 1995/07/18 11:48:57 aas Exp $

# Implementation of the gopher protocol (RFC 1436)
#
# This code is based on 'wwwgopher.pl,v 0.10 1994/10/17 18:12:34 shelden'
# which in turn is a vastly modified version of Oscar's http'get()
# dated 28/3/94 in <ftp://cui.unige.ch/PUBLIC/oscar/scripts/http.pl>
# including contributions from Marc van Heyningen and Martijn Koster.
#


package LWP::Protocol::gopher;

require LWP::Protocol;
require LWP::Request;
require LWP::Response;
require LWP::StatusCode;
require LWP::Socket;

use Carp;

@ISA = qw(LWP::Protocol);


%gopher2mime = (
    '0' => 'text/plain',                # file
    '1' => 'text/html',                 # menu
    '9'	=> 'application/octet-stream',  # binary
    'h' => 'text/html',                 # html
    'g' => 'image/gif',                 # gif
    'I'	=> 'image/*',                   # some kind of image
);


sub request
{
    my($self, $request, $proxy, $arg, $size) = @_;

    LWP::Debug::trace('gopher::request(' . 
                      (defined $request ? $request : '<undef>') . ', ' .
                      (defined $arg ? $arg : '<undef>') . ', ' .
                      (defined $size ? $size : '<undef>') .')');

    $size = 4096 unless defined $size and $size > 0;

    # check proxy
    if (defined $proxy)
    {
        return new LWP::Response &LWP::StatusCode::RC_BAD_REQUEST,
                                 'You can not proxy through the gopher';
    }

    my $url = $request->url;
    if ($url->scheme ne 'gopher') {
	my $scheme = $url->scheme;
        return new LWP::Response &LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                       "LWP::Protocol::gopher::request called for '$scheme'";
    }

    # check method
    $method = $request->method;

    unless ($method eq 'GET' || $method eq 'HEAD') {
        return new LWP::Response &LWP::StatusCode::RC_BAD_REQUEST,
                                 'Library does not allow method ' .
                                 "$method for 'gopher:' URLs";
    }

    my $gophertype = $url->gtype;
    unless (exists $gopher2mime{$gophertype}) {
        return new LWP::Response &LWP::StatusCode::RC_NOT_IMPLEMENTED,
                                 'Library does not support gophertype ' .
                                 $gophertype;
    }

    my $response = new LWP::Response &LWP::StatusCode::RC_OK,
                                     'Document follows';
    $response->header('MIME-Version', '1.0');
    $response->header('Content-type', $gopher2mime{$gophertype}
		                      || 'text/plain');

    return $response if $method eq 'HEAD';  # XXX: don't even try it
    
    my $host = $url->host;
    my $port = $url->port;

    my $requestLine = "";

    my $selector = $url->selector;
    if (defined $selector) {
	$requestLine .= $selector;
	my $search = $url->search;
	if (defined $search) {
	    $requestLine .= "\t$search";
	    my $string = $url->string;
	    if (defined $string) {
		$requestLine .= "\t$string";
	    }
	}
	
    }
    $requestLine .= "\r\n";

    # potential request headers are just ignored

    # Ok, lets make the request
    my $socket = new LWP::Socket;
    alarm($timeout) if $self->useAlarm and defined $timeout;

    $socket->open($host, $port);
    LWP::Debug::debug('connected');

    LWP::Debug::conns("sending request: $requestLine");
    $socket->write($requestLine);
    
    # XXX: the callback now gets raw gopher data.  This is not be the
    # right thing to do.
    $response = $self->collect($arg, $response, sub { 
        LWP::Debug::debug('collecting');
        my $content = '';
        my $result = $socket->readUntil(undef, \$content, $size, $timeout);
        LWP::Debug::debug("collected: $content");
        return \$content;
        } );
    $response->content(menu2html($response->content)) if ($gophertype eq '1');
    
    $response;
}


sub gopher2url
{
    my($gophertype, $path, $host, $port) = @_;

    my $url;

    if ($gophertype eq '8' || $gophertype eq 'T') {
	# telnet session
	$url = new URI::URL ($gophertype eq '8' ? 'telnet:' : 'tn3270:');
	$url->user($path) if defined $path;
    } else {
	$path = URI::URL::uri_escape($path);
	$url = new URI::URL "gopher:/$gophertype$path";
    }
    $url->host($host);
    $url->port($port);
    $url;
}

sub menu2html {
    my($menu) = @_;

    $menu =~ s/\r//g;
    my $tmp = <<"EOT";
<HTML>
<HEAD>
   <TITLE>Gopher menu</TITLE>
</HEAD>
<BODY>
EOT
    for (split("\n", $menu)) {
	last if /^\./;
	my($pretty, $path, $host, $port) = split("\t");

	$pretty =~ s/^(.)//;
	my $type = $1;
	
	my $url = gopher2url($type, $path, $host, $port)->as_string;
	$tmp .= qq{<A HREF="$url">$pretty</A><BR>\n};
    }
    $tmp .= "</BODY>\n</HTML>\n";
    $tmp
}
		
1;
