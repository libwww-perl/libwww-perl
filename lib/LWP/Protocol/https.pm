#
# $Id: https.pm,v 1.9 2001/10/26 17:27:19 gisle Exp $

use strict;

package LWP::Protocol::https;

use vars qw(@ISA);

require LWP::Protocol::http;
require LWP::Protocol::https10;

@ISA = qw(LWP::Protocol::http10);
my $SSL_CLASS = $LWP::Protocol::https::SSL_CLASS;

#we need this to setup a proper @ISA tree
{
    package LWP::Protocol::MyHTTPS;
    use vars qw(@ISA);
    @ISA = ($SSL_CLASS, 'LWP::Protocol::MyHTTP');

    #we need to call both Net::SSL::configure and Net::HTTP::configure
    #however both call SUPER::configure (which is IO::Socket::INET)
    #to avoid calling that twice we override Net::HTTP's
    #_http_socket_configure

    sub configure {
        my $self = shift;
        for my $class (@ISA) {
            my $cfg = $class->can('configure');
            $cfg->($self, @_);
        }
        $self;
    }

    sub _http_socket_configure {
	$_[0];
    }
}

sub _conn_class {
    "LWP::Protocol::MyHTTPS";
}

{
    #if we inherit from LWP::Protocol::https we inherit from
    #LWP::Protocol::http, so just setup aliases for these two
    no strict 'refs';
    for (qw(_check_sock _get_sock_info)) {
        *{"$_"} = \&{"LWP::Protocol::https::$_"};
    }
}

1;
