package Net::HTTPS;

# $Id: HTTPS.pm,v 1.1 2001/11/17 01:42:46 gisle Exp $

use strict;
use vars qw($VERSION $SSL_SOCKET_CLASS @ISA);

$VERSION = "0.01";

# Figure out which SSL implementation to use
if ($IO::Socket::SSL::VERSION) {
    $SSL_SOCKET_CLASS = "IO::Socket::SSL"; # it was already loaded
}
else {
    eval { require Net::SSL; };     # from Crypt-SSLeay
    if ($@) {
	my $old_errsv = $@;
	eval {
	    require IO::Socket::SSL;
	};
	if ($@) {
	    $old_errsv =~ s/\s\(\@INC contains:.*\)/)/g;
	    die $old_errsv . $@;
	}
	$SSL_SOCKET_CLASS = "IO::Socket::SSL";
    }
    else {
	$SSL_SOCKET_CLASS = "Net::SSL";
    }
}

require Net::HTTP::Methods;

@ISA=($SSL_SOCKET_CLASS, 'Net::HTTP::Methods');

sub configure {
    my($self, $cnf) = @_;
    $self->http_configure($cnf);
}

sub http_connect {
    my($self, $cnf) = @_;
    $self->SUPER::configure($cnf);
}

sub http_default_port {
    443;
}

1;
