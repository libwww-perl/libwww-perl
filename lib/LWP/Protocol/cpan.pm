package LWP::Protocol::cpan;

use strict;
use vars qw(@ISA);

require LWP::Protocol;
@ISA = qw(LWP::Protocol);

require URI;
require HTTP::Status;
require HTTP::Response;

my $CPAN = "http://cpan.org/";

sub request {
    my($self, $request, $proxy, $arg, $size) = @_;
    # check proxy
    if (defined $proxy)
    {
	return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
				   'You can not proxy with cpan');
    }

    # check method
    my $method = $request->method;
    unless ($method eq 'GET' || $method eq 'HEAD') {
	return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
				   'Library does not allow method ' .
				   "$method for 'cpan:' URLs");
    }

    my $path = $request->uri->path;
    $path =~ s,^/,,;

    my $response = HTTP::Response->new(&HTTP::Status::RC_FOUND);
    $response->header("Location" => URI->new_abs($path, $CPAN));
    $response;
}

1;
