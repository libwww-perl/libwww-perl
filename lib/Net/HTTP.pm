package Net::HTTP;

# $Id: HTTP.pm,v 1.7 2001/04/09 20:55:44 gisle Exp $

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
	$host .= ":" . $sock->peerport unless $host =~ /:/;
	$sock->host($host);
	$sock->keep_alive($keep_alive);
	$sock->http_version($http_version);
	$sock->peer_http_version($peer_http_version);
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

    push(@{${*$self}{'http_request_method'}}, $method);

    my $ver = ${*$self}{'http_version'};
    $self->autoflush(0);

    my $peer_ver = ${*$self}{'peer_http_version'} || "1.0";
    my $keep_alive = ${*$self}{'http_keep_alive'};

    print $self "$method $uri HTTP/$ver$CRLF";
    if ($keep_alive) {
	if ($peer_ver eq "1.0") {
	    # XXX from looking at Netscape's headers
	    print $self "Keep-Alive: 300$CRLF";
	    print $self "Connection: Keep-Alive$CRLF";
	}
    }
    else {
	print $self "Connection: close$CRLF" if $ver ge "1.1";
    }

    my %given = (host => 0, "content-type" => 0);
    while (@headers) {
	my($k, $v) = splice(@headers, 0, 2);
	my $lc_k = lc($k);
	if ($lc_k eq "connection" || $lc_k eq "te") {
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


sub read_line {
    my $self = shift;
    local $/ = "\012";
    my $line = readline($self);
    return undef unless defined $line;
    $line =~ s/\015?\012\z//;
    return $line;
}


sub read_response_headers {
    my $self = shift;
    my $status = read_line($self);
    die "EOF instead of reponse status line" unless defined $status;
    my($peer_ver, $code, $message) = split(' ', $status, 3);
    die "Bad response status line: $status" unless $peer_ver =~ s,^HTTP/,,;
    ${*$self}{'http_peer_version'} = $peer_ver;
    ${*$self}{'http_status'} = $code;
    my @headers;
    while (my $line = read_line($self)) {
	if ($line =~ /^(\S+)\s*:\s*(.*)/s) {
	    push(@headers, $1, $2);
	}
	elsif (@headers && $line =~ s/^\s+//) {
	    $headers[-1] .= " " . $line;
	}
	else {
	    die "Bad header: $line\n";
	}
    }

    # pick out headers that read_entity_body might need
    my @te;
    my $content_length;
    for (my $i = 0; $i < @headers; $i += 2) {
	my $h = lc($headers[$i]);
	if ($h eq 'transfer-encoding') {
	    push(@te, $headers[$i+1]);
	}
	elsif ($h eq 'content-length') {
	    $content_length = $headers[$i+1];
	}
    }
    ${*$self}{'http_te'} = join("", @te);
    ${*$self}{'http_content_length'} = $content_length;
    ${*$self}{'http_first_body'}++;

    ($peer_ver, $code, $message, @headers);
}


sub read_entity_body {
    my $self = shift;
    my $buf_ref = \$_[0];
    my $size = $_[1];

    my $chunked;
    my $bytes;

    if (${*$self}{'http_first_body'}) {
	${*$self}{'http_first_body'} = 0;
	my $method = shift(@{${*$self}{'http_request_method'}});
	my $status = ${*$self}{'http_status'};
	if ($method eq "HEAD" || $status =~ /^(?:1|[23]04)/) {
	    # these responses are always empty
	    $bytes = 0;
	}
	elsif (my $te = ${*$self}{'http_te'}) {
	    die "Don't know about transfer encoding '$te'"
		unless $te eq "chunked";
	    $chunked = -1;
	}
	elsif (defined(my $content_length = ${*$self}{'http_content_length'})) {
	    $bytes = $content_length;
	}
	else {
	    # XXX Multi-Part types are self delimiting, but RFC 2616 says we
	    # only has to deal with 'multipart/byteranges'

	    # Read until EOF
	}
    }
    else {
	$chunked = ${*$self}{'http_chunked'};
	$bytes   = ${*$self}{'http_bytes'};
    }

    if (defined $chunked) {
	if ($chunked > 0) {
	    my $n = $chunked;
	    $n = $size if $size && $size < $n;
	    $n = read($self, $$buf_ref, $n);
	    ${*$self}{'http_chunked'} = $chunked - $n;
	    return $n;
	}
	else {
	    my $line = read_line($self);
	    if ($chunked == 0) {
		die unless $line eq "";
		$line = read_line($self);
	    }
	    $line =~ s/;.*//;  # ignore potential chunk parameters
	    $line =~ s/\s+$//;
	    my $n = hex($line);
	    if ($n) {
		${*$self}{'http_chunked'} = $n;
		$$buf_ref = "";
		return "0E0";
	    }
	    else {
		# read trailers
		read_line($self) eq "" || die;
		$$buf_ref = "";
		return 0;
	    }
	}
    }
    elsif (defined $bytes) {
	return 0 unless $bytes;
	my $n = $bytes;
	$n = $size if $size && $size < $n;
	$n = read($self, $$buf_ref, $n);
	${*$self}{'http_bytes'} = $bytes - $n;
	return $n;
    }
    else {
	# read until eof
	return read($self, $$buf_ref, $size) if $size > 0;

	# slurp rest
	local $/ = undef;
	$$buf_ref = <$self>;
	return length($$buf_ref);
    }
}

1;
