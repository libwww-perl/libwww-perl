#
# $Id: https11.pm,v 1.1 2001/08/28 04:11:04 gisle Exp $

use strict;

package LWP::Protocol::https11;

use vars qw(@ISA);

require LWP::Protocol::http11;
require LWP::Protocol::https;

@ISA = qw(LWP::Protocol::http11);
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
