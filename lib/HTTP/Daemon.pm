# $Id: Daemon.pm,v 1.2 1996/10/16 16:27:42 aas Exp $
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
  Content-Type: text/html
  
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
client.

=back

=head1 SEE ALSO

L<IO::Socket>

=head1 COPYRIGHT

Copyright 1996, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use vars qw($VERSION @ISA);

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

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
use HTTP::Status qw(RC_OK status_message);
use URI::URL;

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
	if ($req =~ /^\w+[^\n]+HTTP\/\d+.\d+\015?\012/) {
	    last if $req =~ /(\015?\012){2}/;
	} elsif ($req =~ /\012/) {
	    last;  # HTTP/0.9 client
	}
    }
    $req =~ s/^(\w+)\s+(\S+)[^\012]*\012//;
    my $r = HTTP::Request->new($1, url($2, $self->daemon->url));
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
	# should read request content from the client
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

sub send_response
{
    my $self = shift;
    my $res = shift;
    if (!ref $res) {
	$res ||= RC_OK;
	$res = HTTP::Response->new($res, @_);
    }
    $res->date(time);
    $res->header(Server => "libwww-perl");
    unless ($res->message) {
	$res->message(status_message($res->code));
    }
    print $self "HTTP/1.0 ", $res->code, " ", $res->message, "\015\012";
    print $self $res->headers_as_string("\015\012");
    print $self "\015\012";
    print $self $res->content;
}

sub daemon
{
    my $self = shift;
    ${*$self}{'httpd_daemon'};
}

1;
