#
# $Id: https.pm,v 1.3 1997/12/15 20:33:17 aas Exp $

package LWP::Protocol::https;

require LWP::SecureSocket;

require LWP::Protocol::http;
@ISA=qw(LWP::Protocol::http);

sub _new_socket
{
    #LWP::SecureSocket->new;
    die "Secure IO::Socket::INET not yet implemented";
}

1;
