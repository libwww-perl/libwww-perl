#!/local/perl/d/bin/perl -w

use strict;

package HTTP::Daemon;

use vars '@ISA';
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

use HTTP::Request ();
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

sub daemon
{
    my $self = shift;
    ${*$self}{'httpd_daemon'};
}



package main;

my $s = new HTTP::Daemon;
die "Can't create daemon: $!" unless $s;

print $s->url, "\n";

my $c = $s->accept;
die "Can't accept" unless $c;

$c->timeout(60);
my $req = $c->get_request;

die "No request" unless $req;

my $abs = $req->url->abs;

print $req->as_string;

print $c "HTTP/1.0 200 OK
Content-Type: text/html

Howdy
";


