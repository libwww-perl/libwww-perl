#
# $Id: https.pm,v 1.4 1997/12/16 19:43:59 aas Exp $

use strict;

package LWP::Protocol::https;

use vars qw(@ISA);

require LWP::Protocol::http;
@ISA=qw(LWP::Protocol::http);

sub _new_socket
{
    my($self, $host, $port, $timeout) = @_;
    my $sock = LWP::SSL_INET->new(PeerAddr => $host,
				  PeerPort => $port,
				  Timeout  => $timeout,
				 );
    die "Can't connect to $host:$port" unless $sock;
    $sock;
}

#
# We create our own subclass of IO::Socket::INET that makes
# the SSL connection mostly transparent.
#

package LWP::SSL_INET;

use vars qw(@ISA);

require Net::SSLeay;
require IO::Socket;
@ISA=qw(IO::Socket::INET);

sub connect
{
    my $self = shift;
    if ($self->SUPER::connect(@_)) {
	my $ctx = Net::SSLeay::CTX_new() or die "Failed to create SSL_CTX $!";
	my $ssl = Net::SSLeay::new($ctx) or die "Failed to create SSL $!";
	Net::SSLeay::set_fd($ssl, fileno($self));
	Net::SSLeay::connect($ssl) or die "SSL connect failed";
	*$self->{'ssl_ctx'} = $ctx;
	*$self->{'ssl_ssl'} = $ssl;
	return $self;
    } else {
	return;
    }
}

sub close
{
    my $self = shift;
    Net::SSLeay::free(*$self->{'ssl_ssl'});
    Net::SSLeay::CTX_free(*$self->{'ssl_ctx'});
    $self->SUPER::close(@_);
}

sub sysread
{
    my $self = shift;
    if (@_ <= 2) {
	$_[0] = Net::SSLeay::read(*$self->{'ssl_ssl'});
	return unless defined($_[0]);
	return length($_[0]);
    } else {
	my $offset = $_[2];
	my $buf = Net::SSLeay::read(*$self->{'ssl_ssl'});
	return unless defined($buf);
	substr($_[0], length($_[0])-1) = $buf;
	return length($buf);
    }
}

sub syswrite
{
    my $self = shift;
    die "syswrite() with offset not implemented" if @_ > 2;
    my $len = $_[1];
    if ($len < length($_[0])) {
	return Net::SSLeay::write(*$self->{'ssl_ssl'}, substr($_[0], 0, $len));
    } else {
	return Net::SSLeay::write(*$self->{'ssl_ssl'}, $_[0]);
    }
}

*read  = \&sysread;
*write = \&syswrite;

1;
