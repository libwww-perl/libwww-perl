# $Id: Daemon.pm,v 1.4 1996/10/17 11:43:38 aas Exp $
#

use strict;

package HTTP::Daemon;

=head1 NAME

HTTP::Daemon - a simple http server class

=head1 SYNOPSIS

  use HTTP::Daemon;
  $d = new HTTP::Daemon;
  print $d->url, "\n";
  $c = $d->accept;
  $r = $c->get_request;
  print $c "HTTP/1.0 200 OK
  Content-Type: text/plain
  
  Howdy
  ";

=head1 DESCRIPTION

Instances of the I<HTTP::Daemon> class are simple http servers that
listens on a socket for incomming requests. The I<HTTP::Daemon> is
also also a sub-class of I<IO::Socket::INET>, so you can do socket
operations directly on it.

The $h->accept call will return when a connection from a client is
available. The returned value will be a reference to a
I<HTTP::Daemon::ClientConn> class which is another I<IO::Socket::INET>
subclass. Calling $c->get_request() will return a I<HTTP::Request>
object reference.

=head1 METHODS

The following is a list of methods that are new (or enhanced) relative
to the I<IO::Socket::INET> base class.

=over 4

=item $d = new HTTP::Deamon

The object constructor takes the same parameters as a new
I<IO::Socket>, but it can also be called without specifying any
object. The deamon will then set up a listen queue of 5 connections
and find some random free port.

=item $d->url

Returns a URL string that can be used to access the server.

=item $c = $d->accept

Same as I<IO::Socket::accept> but will return an
I<HTTP::Deamon::ClientConn> reference.

=back

The I<HTTP::Deamon::ClientConn> is also a I<IO::Socket::INET>
subclass. The following methods differ.

=over 4

=item $c->get_request

Will read data from the client and turn it into a I<HTTP::Request>
object which is returned. Will return undef if reading of the request
failed.

=item $c->daemon

Return a reference to the corresponding I<HTTP::Daemon> object.

=item $c->send_response( [$res] )

Takes a I<HTTP::Response> object as parameter and send it back to the
client as the response.

=item $c->send_redirect( $loc, [$code, [$message]] )

Sends a redirect response back to the client.  The location ($loc) can
be an abolute or a relative URL. The $code must be one the redirect
status codes.

=item $c->send_file_response($filename)

Send back a response with the specified $filename as content.

=item $c->send_file($fd);

Copies the file back to the client.  The file can be a string (which
will be interpreted as a filename) or a reference to a glob.

=item $c->send_status_line( [$code, [$mess, [$proto]]] )

Sends the status line back to the client.

=item $c->send_basic_header( [$code, [$mess, [$proto]]] )

Sends the status line and the "Date:" and "Server:" headers back to
the client.

=back

=head1 SEE ALSO

L<IO::Socket>

=head1 COPYRIGHT

Copyright 1996, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use vars qw($VERSION @ISA);

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

use IO::Socket ();
@ISA=qw(IO::Socket::INET);


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


sub accept
{
    my $self = shift;
    my $sock = $self->SUPER::accept(@_);
    $sock = bless $sock, "HTTP::Daemon::ClientConn" if $sock;
    ${*$sock}{'httpd_daemon'} = $self;
    $sock;
}


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

my $NL = "\015\012";   # "\r\n" is not portable


sub get_request
{
    my $self = shift;
    my $req = my $buf = "";
    
    my $timeout = ${*$self}{'io_socket_timeout'};
    my  $fdset = "";
    vec($fdset, $self->fileno,1) = 1;

    while (1) {
	if ($timeout) {
	    return undef unless select($fdset,undef,undef,$timeout);
	}
	my $n = sysread($self, $buf, 1024);
	return undef if $n == 0;  # unexpected EOF
	#print length($buf), " bytes read\n";
	$req .= $buf;
	if ($req =~ /^\w+[^\n]+HTTP\/\d+\.\d+\015?\012/) {
	    last if $req =~ /(\015?\012){2}/;
	} elsif ($req =~ /\012/) {
	    last;  # HTTP/0.9 client
	}
    }
    $req =~ s/^(\w+)\s+(\S+)(?:\s+(HTTP\/\d+\.\d+))?[^\012]*\012//;
    my $proto = $3 || "HTTP/0.9";
    my $r = HTTP::Request->new($1, url($2, $self->daemon->url));
    $r->protocol($3);
    while ($req =~ s/^([\w\-]+):\s*([^\012]*)\012//) {
	my($key,$val) = ($1, $2);
	$val =~ s/\015$//;
	$r->header($key => $val);
	#XXX: must handle header continuation lines
    }
    if ($req) {
	unless ($req =~ s/^\015?\012//) {
	    warn "Headers not terminated by blank in request";
	}
    }
    my $len = $r->content_length;
    if ($len) {
	# should read request entity body from the client
	$len -= length($req);
	while ($len > 0) {
	    if ($timeout) {
		return undef unless select($fdset,undef,undef,$timeout);
	    }
	    my $n = sysread($self, $buf, 1024);
	    return undef if $n == 0;
	    $req .= $buf;
	    $len -= $n;
	}
	$r->content($req);
    }
    $r;
}


sub send_status_line
{
    my($self, $status, $message, $proto) = @_;
    $status  ||= RC_OK;
    $message ||= status_message($status);
    $proto   ||= "HTTP/1.0";
    print $self "$proto $status $message$NL";
}


sub send_crlf
{
    my $self = shift;
    print $self $NL;
}


sub send_basic_header
{
    my $self = shift;
    $self->send_status_line(@_);
    print $self "Date: ", time2str(time), "$NL";
    print $self "Server: libwww-perl-daemon/$HTTP::Daemon::VERSION\015\12";
}


sub send_response
{
    my $self = shift;
    my $res = shift;
    if (!ref $res) {
	$res ||= RC_OK;
	$res = HTTP::Response->new($res, @_);
    }
    $self->send_basic_header($res->code, $res->message, $res->protocol);
    print $self $res->headers_as_string("$NL");
    print $self $NL;  # separates headers and content
    print $self $res->content;
}


sub send_redirect
{
    my($self, $loc, $status, $content) = @_;
    $status ||= RC_MOVED_PERMANENTLY;
    Carp::croak("Status '$status' is not redirect") unless is_redirect($status);

    $loc = url($loc, $self->daemon->url) unless ref($loc);
    $loc = $loc->abs;
    print $self "Location: $loc$NL";
    if ($content) {
	my $ct = $content =~ /^\s*</ ? "text/html" : "text/plain";
	print $self "Content-Type: $ct$NL";
    }
    print $self $NL;
    print $self $content if $content;
}


sub send_error
{
    my($self, $status, $error) = @_;
    $status ||= RC_BAD_REQUEST;
    Carp::croak("Status '$status' is not an error") unless is_error($status);
    my $mess = status_message($status);
    $error  ||= "";
    $self->send_basic_header($status);
    print $self "Content-Type: text/html$NL";
    print $self "$NL";
    print $self <<EOT;
<title>$status $mess</title>
<h1>$status $mess</title>
$error
EOT
    $status;
}


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
	$self->send_basic_header;
	print $self "Content-Type: $ct$NL";
	print $self "Content-Encoding: $ce$NL" if $ce;
	print $self "Content-Length: $size$NL";
	print $self "Last-Modified: ", time2str($mtime), "$NL";
	print $self "$NL";
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


sub daemon
{
    my $self = shift;
    ${*$self}{'httpd_daemon'};
}

1;
