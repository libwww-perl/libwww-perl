#
# $Id: https.pm,v 1.2 1997/08/05 14:36:58 aas Exp $

package LWP::Protocol::https;

require LWP::SecureSocket;

require LWP::Protocol::http;
@ISA=qw(LWP::Protocol::http);

sub _new_socket
{
    LWP::SecureSocket->new;
}

1;
