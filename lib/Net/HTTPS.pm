package Net::HTTPS;

use strict;
use vars qw($VERSION $SSL_SOCKET_CLASS @ISA);

$VERSION = "5.819";

# Figure out which SSL implementation to use
if ($SSL_SOCKET_CLASS) {
    # somebody already set it
}
elsif ($SSL_SOCKET_CLASS = $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS}) {
    unless ($SSL_SOCKET_CLASS =~ /^(IO::Socket::SSL|Net::SSL)\z/) {
	die "Bad socket class [$SSL_SOCKET_CLASS]";
    }
    eval "require $SSL_SOCKET_CLASS";
    die $@ if $@;
}
elsif ($IO::Socket::SSL::VERSION) {
    $SSL_SOCKET_CLASS = "IO::Socket::SSL"; # it was already loaded
}
elsif ($Net::SSL::VERSION) {
    $SSL_SOCKET_CLASS = "Net::SSL";
}
else {
    eval { require IO::Socket::SSL; };
    if ($@) {
	my $old_errsv = $@;
	eval {
	    require Net::SSL;  # from Crypt-SSLeay
	};
	if ($@) {
	    $old_errsv =~ s/\s\(\@INC contains:.*\)/)/g;
	    die $old_errsv . $@;
	}
	$SSL_SOCKET_CLASS = "Net::SSL";
    }
    else {
	$SSL_SOCKET_CLASS = "IO::Socket::SSL";
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
    if ($self->isa("Net::SSL")) {
	if ($cnf->{SSL_verify_mode}) {
	    if (my $f = $cnf->{SSL_ca_file}) {
		$ENV{HTTPS_CA_FILE} = $f;
	    }
	    if (my $f = $cnf->{SSL_ca_path}) {
		$ENV{HTTPS_CA_DIR} = $f;
	    }
	}
	if ($cnf->{SSL_verifycn_scheme}) {
	    $@ = "Net::SSL from Crypt-SSLeay can't verify hostnames; either install IO::Socket::SSL or turn off verification by setting the PERL_LWP_SSL_VERIFY_HOSTNAME environment variable to 0";
	    return undef;
	}
    }
    $self->SUPER::configure($cnf);
}

sub http_default_port {
    443;
}

# The underlying SSLeay classes fails to work if the socket is
# placed in non-blocking mode.  This override of the blocking
# method makes sure it stays the way it was created.
sub blocking { }  # noop

1;
