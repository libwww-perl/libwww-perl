package LWP::Protocol::loopback;

use strict;
use vars qw(@ISA);
require HTTP::Response;
require HTTP::Status;
require LWP::Protocol;
@ISA = qw(LWP::Protocol);

sub request {
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;

    my $response = HTTP::Response->new(200, "OK");
    $response->content_type("message/http; msgtype=request");

    if ($proxy) {
	$request = $request->clone;
	$request->push_header("Via", "loopback/1.0 $proxy");
    }

    return $self->collect_once($arg, $response, $request->as_string);
}

1;
