# $Id: Daemon.pm,v 1.13 1996/11/13 13:22:21 aas Exp $
#

use strict;

package HTTP::Daemon;

=head1 NAME

HTTP::Daemon - a simple http server class

=head1 SYNOPSIS

  use HTTP::Daemon;
  use HTTP::Status;

  $d = new HTTP::Daemon;
  print "Please contact me at: <URL:", $d->url, ">\n";
  while ($c = $d->accept) {
      $r = $c->get_request;
      if ($r) {
	  if ($r->method eq 'GET' and $r->url->path eq "/xyzzy") {
              # this is *not* recommened practice
	      $c->send_file_response("/etc/passwd");
	  } else {
	      $c->send_error(RC_FORBIDDEN)
	  }
      }
      $c = undef;  # close connection
  }

=head1 DESCRIPTION

Instances of the I<HTTP::Daemon> class are HTTP/1.1 servers that
listens on a socket for incoming requests. The I<HTTP::Daemon> is a
sub-class of I<IO::Socket::INET>, so you can do socket operations
directly on it.

The accept() method will return when a connection from a client is
available. The returned value will be a reference to a object of the
I<HTTP::Daemon::ClientConn> class which is another I<IO::Socket::INET>
subclass. Calling the get_request() method on this object will read
data from the client and return an I<HTTP::Request> object reference.

This HTTP daemon does not fork(2) for you.  Your application, i.e. the
user of the I<HTTP::Daemon> is reponsible for forking if that is
desirable.  Also note that the user is responsible for generating
responses that conforms to the HTTP/1.1 protocol.  The
I<HTTP::Daemon::ClientConn> provide some methods that make this easier.

=head1 METHODS

The following is a list of methods that are new (or enhanced) relative
to the I<IO::Socket::INET> base class.

=over 4

=cut


use vars qw($VERSION @ISA $PROTO);

$VERSION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);

use IO::Socket ();
@ISA=qw(IO::Socket::INET);

$PROTO = "HTTP/1.1";

=item $d = new HTTP::Daemon

The object constructor takes the same parameters as the
I<IO::Socket::INET> constructor.  It can also be called without
specifying any parameters. The daemon will then set up a listen queue
of 5 connections and allocate some random port number.  A server
that want to bind to some specific address on the standard HTTP port
will be constructed like this:

  $d = new HTTP::Daemon
        LocalAddr => 'www.someplace.com',
        LocalPort => 80;

=cut

sub new
{
    my($class, %args) = @_;
    $args{Listen} ||= 5;
    $args{Proto}  ||= 'tcp';
    my $self = $class->SUPER::new(%args);
    return undef unless $self;

    my $host = $args{LocalAddr};
    unless ($host) {
	require Sys::Hostname;
	$host = Sys::Hostname::hostname();
    }
    ${*$self}{'httpd_server_name'} = $host;
    $self;
}


=item $c = $d->accept

Same as I<IO::Socket::accept> but will return an
I<HTTP::Daemon::ClientConn> reference.  It will return undef if you
have specified a timeout and no connection is made within that time.

=cut

sub accept
{
    my $self = shift;
    my $sock = $self->SUPER::accept(@_);
    if ($sock) {
	$sock = bless $sock, "HTTP::Daemon::ClientConn";
	${*$sock}{'httpd_daemon'} = $self;
    }
    $sock;
}


=item $d->url

Returns a URL string that can be used to access the server root.

=cut

sub url
{
    my $self = shift;
    my $url = "http://";
    $url .= ${*$self}{'httpd_server_name'};
    my $port = $self->sockport;
    $url .= ":$port" if $port != 80;
    $url .= "/";
    $url;
}


=item $d->product_tokens

Returns the name that this server will use to identify itself.  This
is the string that is sent with the I<Server> response header.

=cut

sub product_tokens
{
    "libwww-perl-daemon/$HTTP::Daemon::VERSION";
}


package HTTP::Daemon::ClientConn;

use vars '@ISA';
use IO::Socket ();
@ISA=qw(IO::Socket::INET);

use HTTP::Request  ();
use HTTP::Response ();
use HTTP::Status;
use HTTP::Date qw(time2str);
use URI::URL qw(url);
use LWP::MediaTypes qw(guess_media_type);
use Carp ();

my $CRLF = "\015\012";   # "\r\n" is not portable

=back

The I<HTTP::Daemon::ClientConn> is also a I<IO::Socket::INET>
subclass. Instances of this class are returned by the accept() method
of the I<HTTP::Daemon>.  The following additional methods are
provided:

=over 4

=item $c->get_request

Will read data from the client and turn it into a I<HTTP::Request>
object which is then returned. Will return undef if reading of the
request failed.  If it fails, then the I<HTTP::Daemon::ClientConn>
object ($c) should be discarded.

The $c->get_request method support HTTP/1.1 content bodies, including
I<chunked> transfer encoding with footer and I<multipart/*> types.

=cut

sub get_request
{
    my $self = shift;
    my $buf = "";
    
    my $timeout = $ {*$self}{'io_socket_timeout'};
    my  $fdset = "";
    vec($fdset, $self->fileno,1) = 1;

  READ_HEADER:
    while (1) {
	if ($timeout) {
	    return undef unless select($fdset,undef,undef,$timeout);
	}
	my $n = sysread($self, $buf, 1024, length($buf));
	return undef if $n == 0;  # unexpected EOF
	if ($buf =~ /^\w+[^\n]+HTTP\/\d+\.\d+\015?\012/) {
	    last READ_HEADER if $buf =~ /(\015?\012){2}/;
	} elsif ($buf =~ /\012/) {
	    last READ_HEADER;  # HTTP/0.9 client
	}
    }
    $buf =~ s/^(\w+)\s+(\S+)(?:\s+(HTTP\/\d+\.\d+))?[^\012]*\012//;
    my $proto = $3 || "HTTP/0.9";
    ${*$self}{'httpd_client_proto'} = $proto;
    my $r = HTTP::Request->new($1, url($2, $self->daemon->url));
    $r->protocol($proto);

    my($key, $val);
  HEADER:
    while ($buf =~ s/^([^\012]*)\012//) {
	$_ = $1;
	s/\015$//;
	if (/^([\w\-]+)\s*:\s*(.*)/) {
	    $r->push_header($key, $val) if $key;
	    ($key, $val) = ($1, $2);
	} elsif (/^\s+(.*)/) {
	    $val .= " $1";
	} else {
	    last HEADER;
	}
    }
    $r->push_header($key, $val) if $key;

    my $te  = $r->header('Transfer-Encoding');
    my $ct  = $r->header('Content-Type');
    my $len = $r->header('Content-Length');

    if ($te && lc($te) eq 'chunked') {
	# Handle chunked transfer encoding
	my $body = "";
      CHUNK:
	while (1) {
	    if ($buf =~ s/^([^\012]*)\012//) {
		my $chunk_head = $1;
		$chunk_head =~ /^([0-9A-Fa-f]+)/;
		return undef unless length($1);
		my $size = hex($1);
		last CHUNK if $size == 0;

		my $missing = $size - length($buf);
		$missing += 2; # also read CRLF at chunk end
		$body .= $buf;
		$buf = "";
		# must read rest of chunk and append it to the $body
		while ($missing > 0) {
		    if ($timeout) {
			return undef unless select($fdset,undef,undef,$timeout);
		    }
		    my $n = sysread($self, $body, $missing, length($body));
		    return undef if $n == 0;
		    $missing -= $n;
		}
		substr($body, -2, 2) = ''; # remove CRLF at end

	    } else {
		# need more data in order to have a complete chunk header
		if ($timeout) {
		    return undef unless select($fdset,undef,undef,$timeout);
		}
		my $n = sysread($self, $buf, 2048, length($buf));
		return undef if $n == 0;
	    }
	}
	$r->content($body);

	# pretend it was a normal entity body
	$r->remove_header('Transfer-Encoding');
	$r->header('Content-Length', length($body));

	my($key, $val);
      FOOTER:
	while (1) {
	    if ($buf !~ /\012/) {
		# need at least one line to look at
		if ($timeout) {
		    return undef unless select($fdset,undef,undef,$timeout);
		}
		my $n = sysread($self, $buf, 2048, length($buf));
		return undef if $n == 0;
	    } else {
		$buf =~ s/^([^\012]*)\012//;
		$_ = $1;
		s/\015$//;
		last FOOTER if length($_) == 0;

		if (/^([\w\-]+)\s*:\s*(.*)/) {
		    $r->push_header($key, $val) if $key;
		    ($key, $val) = ($1, $2);
		} elsif (/^\s+(.*)/) {
		    $val .= " $1";
		} else {
		    return undef;  # bad syntax
		}
	    }
	}
	$r->push_header($key, $val) if $key;

    } elsif ($te) {
	# Unknown transfer encoding
	$self->send_error(501);
	return undef;

    } elsif ($ct && lc($ct) =~ m/^multipart\/\w+\s*;.*boundary\s*=\s*(\w+)/) {
	# Handle multipart content type
	my $boundary = "$CRLF--$1--$CRLF";
	while (index($buf, $boundary) < 0) {
	    # end marker not yet found
	    if ($timeout) {
		return undef unless select($fdset,undef,undef,$timeout);
	    }
	    my $n = sysread($self, $buf, 2048, length($buf));
	    return undef if $n == 0;
	}
	$r->content($buf);

    } elsif ($len) {
	# Plain body specified by "Content-Length"

	$len -= length($buf);
	while ($len > 0) {
	    if ($timeout) {
		return undef unless select($fdset,undef,undef,$timeout);
	    }
	    my $n = sysread($self, $buf, $len, length($buf));
	    return undef if $n == 0;
	    $len -= $n;
	}
	$r->content($buf);

    }

    $r;
}


=item $c->antique_client

Returns TRUE if the client speaks the HTTP/0.9 protocol, i.e. no
status code or headers should be returned.

=cut

sub antique_client
{
    my $self = shift;
    ${*$self}{'httpd_client_proto'} eq 'HTTP/0.9';
}


=item $c->send_status_line( [$code, [$mess, [$proto]]] )

Sends the status line back to the client.

=cut

sub send_status_line
{
    my($self, $status, $message, $proto) = @_;
    return if $self->antique_client;
    $status  ||= RC_OK;
    $message ||= status_message($status);
    $proto   ||= $HTTP::Daemon::PROTO;
    print $self "$proto $status $message$CRLF";
}


sub send_crlf
{
    my $self = shift;
    print $self $CRLF;
}


=item $c->send_basic_header( [$code, [$mess, [$proto]]] )

Sends the status line and the "Date:" and "Server:" headers back to
the client.

=cut

sub send_basic_header
{
    my $self = shift;
    return if $self->antique_client;
    $self->send_status_line(@_);
    print $self "Date: ", time2str(time), $CRLF;
    my $product = $self->daemon->product_tokens;
    print $self "Server: $product$CRLF" if $product;
}


=item $c->send_response( [$res] )

Takes a I<HTTP::Response> object as parameter and send it back to the
client as the response.

=cut

sub send_response
{
    my $self = shift;
    my $res = shift;
    if (!ref $res) {
	$res ||= RC_OK;
	$res = HTTP::Response->new($res, @_);
    }
    unless ($self->antique_client) {
	$self->send_basic_header($res->code, $res->message, $res->protocol);
	print $self $res->headers_as_string($CRLF);
	print $self $CRLF;  # separates headers and content
    }
    print $self $res->content;
}


=item $c->send_redirect( $loc, [$code, [$entity_body]] )

Sends a redirect response back to the client.  The location ($loc) can
be an absolute or a relative URL. The $code must be one the redirect
status codes, and it defaults to "301 Moved Permanently"

=cut

sub send_redirect
{
    my($self, $loc, $status, $content) = @_;
    $status ||= RC_MOVED_PERMANENTLY;
    Carp::croak("Status '$status' is not redirect") unless is_redirect($status);
    $self->send_basic_header($status);
    $loc = url($loc, $self->daemon->url) unless ref($loc);
    $loc = $loc->abs;
    print $self "Location: $loc$CRLF";
    if ($content) {
	my $ct = $content =~ /^\s*</ ? "text/html" : "text/plain";
	print $self "Content-Type: $ct$CRLF";
    }
    print $self $CRLF;
    print $self $content if $content;
}


=item $c->send_error( [$code, [$error_message]] )

Send an error response back to the client.  If the $code is missing a
"Bad Request" error is reported.  The $error_message is a string that
is incorporated in the body of the HTML entity body.

=cut

sub send_error
{
    my($self, $status, $error) = @_;
    $status ||= RC_BAD_REQUEST;
    Carp::croak("Status '$status' is not an error") unless is_error($status);
    my $mess = status_message($status);
    $error  ||= "";
    unless ($self->antique_client) {
        $self->send_basic_header($status);
        print $self "Content-Type: text/html$CRLF";
        print $self $CRLF;
    }
    print $self <<EOT;
<title>$status $mess</title>
<h1>$status $mess</h1>
$error
EOT
    $status;
}


=item $c->send_file_response($filename)

Send back a response with the specified $filename as content.  If the
file happen to be a directory we will generate a HTML index for it.

=cut

sub send_file_response
{
    my($self, $file) = @_;
    if (-d $file) {
	$self->send_dir($file);
    } elsif (-f _) {
	# plain file
	local(*F);
	sysopen(F, $file, 0) or 
	  return $self->send_error(RC_FORBIDDEN);
	my($ct,$ce) = guess_media_type($file);
	my($size,$mtime) = (stat _)[7,9];
	unless ($self->antique_client) {
	    $self->send_basic_header;
	    print $self "Content-Type: $ct$CRLF";
	    print $self "Content-Encoding: $ce$CRLF" if $ce;
	    print $self "Content-Length: $size$CRLF";
	    print $self "Last-Modified: ", time2str($mtime), "$CRLF";
	    print $self $CRLF;
	}
	$self->send_file(\*F);
	return RC_OK;
    } else {
	$self->send_error(RC_NOT_FOUND);
    }
}


sub send_dir
{
    my($self, $dir) = @_;
    $self->send_error(RC_NOT_FOUND) unless -d $dir;
    $self->send_error(RC_NOT_IMPLEMENTED);
}


=item $c->send_file($fd);

Copies the file back to the client.  The file can be a string (which
will be interpreted as a filename) or a reference to a glob.

=cut

sub send_file
{
    my($self, $file) = @_;
    my $opened = 0;
    if (!ref($file)) {
	local(*F);
	open(F, $file) || return undef;
	$file = \*F;
	$opened++;
    }
    my $cnt = 0;
    my $buf = "";
    my $n;
    while ($n = sysread($file, $buf, 8*1024)) {
	last if $n <= 0;
	$cnt += $n;
	print $self $buf;
    }
    close($file) if $opened;
    $cnt;
}


=item $c->daemon

Return a reference to the corresponding I<HTTP::Daemon> object.

=cut

sub daemon
{
    my $self = shift;
    ${*$self}{'httpd_daemon'};
}

=back

=head1 SEE ALSO

L<IO::Socket>, L<Apache>

=head1 COPYRIGHT

Copyright 1996, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
