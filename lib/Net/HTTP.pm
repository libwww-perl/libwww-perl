package Net::HTTP;

# $Id: HTTP.pm,v 1.1 2001/04/05 15:41:11 gisle Exp $

use strict;
use vars qw($VERSION @ISA);

$VERSION = "0.01";
require IO::Socket::INET;
@ISA=qw(IO::Socket::INET);

my $CRLF = "\015\012";   # "\r\n" is not portable

sub configure {
    my($self, $cnf) = @_;
    require Data::Dump;
    Data::Dump::dump($cnf);
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

    my $sock = $self->SUPER::configure($cnf);
    if ($sock) {
	unless ($host =~ /:/) {
	    $host .= ":" . $sock->peerport;
	}
	${*$sock}{'http_host'} = $host;
    }
    return $sock;
}

sub send_request {
    my $self = shift;
    my $method = shift;
    my $uri = shift;
    my $content = (@_ && @_ % 2) ? pop : "";
    my @headers = @_;

    my $prot = ${*$self}{'http_prot'} || "HTTP/1.1";
    $self->autoflush(0);

    print $self "$method $uri $prot$CRLF";
    print $self "Connection: close$CRLF";
    print $self "Host: ${*$self}{'http_host'}$CRLF";

    my $ct_given;
    while (@headers) {
	my($k, $v) = splice(@headers, 0, 2);
	my $lc_k = lc($k);
	if ($lc_k eq "connection") {
	    next;
	}
	elsif ($lc_k eq "content-length") {
	   $ct_given++; 
	}
	print $self "$k: $v$CRLF";
    }
    if (length($content) && !$ct_given) {
	print $self "Content-length: " . length($content) . $CRLF;
    }

    print $self $CRLF;
    $self->autoflush(1);

    print $self $content;
}

sub read_response {
    my $self = shift;
    
}

1;
