#
# $Id: https.pm,v 1.1 1997/08/05 14:27:39 aas Exp $

package LWP::Protocol::https;

require require LWP::SecureSocket;

require LWP::Protocol::http;
@ISA=qw(LWP::Protocol::http);

sub _new_socket
{
    LWP::SecureSocket->new;
}

1;
