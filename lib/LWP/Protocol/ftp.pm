#
# $Id: ftp.pm,v 1.1 1995/07/18 19:37:58 aas Exp $

# Implementation of the ftp protocol (RFC 959)
#
#

package LWP::Protocol::ftp;

require LWP::Protocol;
require LWP::Request;
require LWP::Response;
require LWP::StatusCode;
require LWP::Socket;

use Carp;

@ISA = qw(LWP::Protocol);


sub request
{
    my($self, $request, $proxy, $arg, $size) = @_;

    LWP::Debug::trace('ftp-request(' . 
                      (defined $request ? $request : '<undef>') . ', ' .
                      (defined $arg ? $arg : '<undef>') . ', ' .
                      (defined $size ? $size : '<undef>') .')');

    $size = 4096 unless defined $size and $size > 0;

    # check proxy
    if (defined $proxy)
    {
        return new LWP::Response &LWP::StatusCode::RC_BAD_REQUEST,
                                 'You can not proxy through the ftp';
    }

    my $url = $request->url;
    if ($url->scheme ne 'ftp') {
        my $scheme = $url->scheme;
        return new LWP::Response &LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                       "LWP::Protocol::ftp::request called for '$scheme'";
    }

    # check method
    $method = $request->method;

    unless ($method eq 'GET' || $method eq 'HEAD' || $method eq 'PUT') {
        return new LWP::Response &LWP::StatusCode::RC_BAD_REQUEST,
                                 'Library does not allow method ' .
                                 "$method for 'ftp:' URLs";
    }

    my $response = new LWP::Response &LWP::StatusCode::RC_OK,
                                     'Document follows';

    my $host     = $url->host;
    my $port     = $url->port;
    my $user     = $url->user;
    my $password = $url->password;
    my $path     = $url->full_path;

    $response->header('Content-Type', 'text/plain');
    $response->content(<<"EOT");
FTP is not working yet.  These are the parameters:

Method = $method
Host   = $host, Port = $port,
User   = $user, Password = $password
Path   = $path;

EOT

    $response;
}
                
1;
