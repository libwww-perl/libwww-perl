#
# $Id: mailto.pm,v 1.1 1995/07/18 13:20:42 aas Exp $
#
# This module implements the mailto protocol.  It is just a simple 
# frontend to the Unix sendmail program.

package LWP::Protocol::mailto;

require LWP::Protocol;
require LWP::Request;
require LWP::Response;
require LWP::StatusCode;

use Carp;

@ISA = qw(LWP::Protocol);

$SENDMAIL = "/usr/lib/sendmail";


sub request
{
    my($self, $request, $proxy, $arg, $size) = @_;

    # check proxy
    if (defined $proxy)
    {
        return new LWP::Response &LWP::StatusCode::RC_BAD_REQUEST,
                                 'You can not proxy with mail';
    }

    # check method
    $method = $request->method;

    if ($method ne 'POST') {
        return new LWP::Response &LWP::StatusCode::RC_BAD_REQUEST,
                                 'Library does not allow method ' .
                                 "$method for 'mailto:' URLs";
    }

    # check url
    my $url = $request->url;

    my $scheme = $url->scheme;
    if ($scheme ne 'mailto') {
        return new LWP::Response &LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                                 "LWP::file::request called for '$scheme'";
    }
    unless (-x $SENDMAIL) {
        return new LWP::Response &LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                                 "You don't have $SENDMAIL";
    }

    open(SENDMAIL, "| $SENDMAIL -oi -t") or
        return new LWP::Response &LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                                 "Can't run $SENDMAIL: $!";

    my $addr = $url->encoded822addr;

    $request->header('To', $addr);
    print SENDMAIL $request->headerAsString;
    print SENDMAIL "\n";
    my $content = $request->content;
    print SENDMAIL $content if $content;
    close(SENDMAIL);
    
    my $response = new LWP::Response &LWP::StatusCode::RC_OK, 'Mail sent';
    $response->header('Content-Type', 'text/plain');
    $response->content("Mail sent to <$addr>\n");

    return $response;
}

1;
