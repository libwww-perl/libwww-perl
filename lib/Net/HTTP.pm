package Net::HTTP;

# $Id: HTTP.pm,v 1.2 2001/04/05 18:08:11 gisle Exp $

use strict;
use vars qw($VERSION @ISA);

$VERSION = "0.01";
require IO::Socket::INET;
@ISA=qw(IO::Socket::INET);

my $CRLF = "\015\012";   # "\r\n" is not portable

sub configure {
    my($self, $cnf) = @_;
    my $host = delete $cnf->{Host};
    my $peer = $cnf->{PeerAddr} || $cnf->{PeerHost};
    if ($host) {
	$cnf->{PeerHost} = $host unless $peer;
    }
    else {
	$host = $peer;
	$host =~ s/:.*//;
    }
    $cnf->{PeerPort} = 80 unless $cnf->{PeerPort};

    my $keep_alive = delete $cnf->{KeepAlive};
    my $http_version = delete $cnf->{HTTPVersion};
    $http_version = "1.1" unless defined $http_version;
    my $peer_http_version = delete $cnf->{PeerHTTPVersion};
    $peer_http_version = "1.0" unless defined $peer_http_version;

    my $sock = $self->SUPER::configure($cnf);
    if ($sock) {
	$self->host($host);
	$self->http_version($http_version);
	$self->peer_http_version($peer_http_version);
	$self->keep_alive($keep_alive);
	$host .= ":" . $sock->peerport unless $host =~ /:/;
	${*$sock}{'http_host'} = $host;
	${*$sock}{'http_keep_alive'} = $keep_alive;
    }
    return $sock;
}

sub host {
    my $self = shift;
    my $old = ${*$self}{'http_host'};
    ${*$self}{'http_host'} = shift if @_;
    $old;
}

sub keep_alive {
    my $self = shift;
    my $old = ${*$self}{'http_keep_alive'};
    ${*$self}{'http_keep_alive'} = shift if @_;
    $old;
}

sub http_version {
    my $self = shift;
    my $old = ${*$self}{'http_version'};
    if (@_) {
	my $v = shift;
	$v = "1.0" if $v eq "1";  # float
	unless ($v eq "1.0" or $v eq "1.1") {
	    require Carp;
	    Carp::croak("Unsupported HTTP version '$v'");
	}
	${*$self}{'http_version'} = $v;
    }
    $old;
}

sub peer_http_version {
    my $self = shift;
    my $old = ${*$self}{'peer_http_version'};
    ${*$self}{'peer_http_version'} = shift if @_;
    $old;
}

sub write_request {
    my $self = shift;
    my $method = shift;
    my $uri = shift;
    my $content = (@_ && @_ % 2) ? pop : "";
    my @headers = @_;

    for ($method, $uri) {
	require Carp;
	Carp::croak("Bad method or uri") if /\s/ || !length;
    }

    my $ver = ${*$self}{'http_version'};
    $self->autoflush(0);

    my $peer_ver = ${*$self}{'peer_http_version'} || "1.0";
    my $keep_alive = ${*$self}{'http_keep_alive'};

    print $self "$method $uri HTTP/$ver$CRLF";
    if ($keep_alive) {
	if ($peer_ver eq "1.0") {
	    # XXX from looking at Netscape's headers
	    print $self "Keep-Alive: 300$CRLF";
	    print $self "Connection: keep-alive$CRLF";
	}
    }
    else {
	print $self "Connection: close$CRLF" if $ver ge "1.1";
    }

    my %given = (host => 0, "content-type" => 0);
    while (@headers) {
	my($k, $v) = splice(@headers, 0, 2);
	my $lc_k = lc($k);
	if ($lc_k eq "connection") {
	    next;  # always ignore these
	}
	elsif (exists $given{$lc_k}) {
	    $given{$lc_k}++;
	}
	print $self "$k: $v$CRLF";
    }

    if (length($content) && !$given{'content-type'}) {
	print $self "Content-length: " . length($content) . $CRLF;
    }
    print $self "Host: ${*$self}{'http_host'}$CRLF"
	unless $given{host};

    print $self $CRLF;
    $self->autoflush(1);

    print $self $content;
}

sub read_response {
    my $self = shift;
}

sub read_line {
    my $self = shift;
    local $/ = "\012";
    my $line = readline($self);
    #Data::Dump::dump("XXX", $line);
    $line =~ s/\015?\012\z//;
    return $line;
}

sub read_response_headers {
    my $self = shift;
    my $status = read_line($self);
    my($peer_ver, $code, $message) = split(' ', $status, 3);
    die unless $peer_ver =~ s,^HTTP/,,;
    ${*$self}{'peer_http_version'} = $peer_ver;
    my @headers;
    while (my $line = read_line($self)) {
	if ($line =~ /^(\S+)\s*:\s*(.*)/s) {
	    push(@headers, $1, $2);
	}
	elsif (@headers && $line =~ s/^\s+//) {
	    $headers[-1] .= " " . $line;
	}
	else {
	    die "Bad header\n";
	}
    }
    ($peer_ver, $code, $message, @headers);
}

sub read_chunked_content {
    my $self = shift;
    my @buf;
    while (my $n = read_line($self)) {
	$n =~ s/\s+$//;
	$n = hex($n);
	my $buf;
	read($self, $buf, $n) == $n || die;
	read_line($self) eq "" || die;
	push(@buf, $buf);
    }
    read_line($self) eq "" || die;
    wantarray ? @buf : join("", @buf);
}

1;
