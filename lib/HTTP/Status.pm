#
# $Id: Status.pm,v 1.20 1997/05/20 20:31:41 aas Exp $

package HTTP::Status;

require 5.002;   # becase we use prototypes

=head1 NAME

HTTP::Status - HTTP Status code processing

=head1 SYNOPSIS

 use HTTP::Status;

 if ($rc != RC_OK) {
     print status_message($rc), "\n";
 }

 if (is_success($rc)) { ... }
 if (is_error($rc)) { ... }
 if (is_redirect($rc)) { ... }

=head1 DESCRIPTION

I<HTTP::Status> is a library of routines for defining and
classification of HTTP status codes for libwww-perl.  Status codes are
used to encode the overall outcome of a HTTP response message.  Codes
correspond to those defined in RFC 2068.

=head1 CONSTANTS

The following constant functions can be used as mnemonic status code
names:

   RC_CONTINUE				(100)
   RC_SWITCHING_PROTOCOLS		(101)

   RC_OK				(200)
   RC_CREATED				(201)
   RC_ACCEPTED				(202)
   RC_NON_AUTHORITATIVE_INFORMATION	(203)
   RC_NO_CONTENT			(204)
   RC_RESET_CONTENT			(205)
   RC_PARTIAL_CONTENT			(206)

   RC_MULTIPLE_CHOICES			(300)
   RC_MOVED_PERMANENTLY			(301)
   RC_MOVED_TEMPORARILY			(302)
   RC_SEE_OTHER				(303)
   RC_NOT_MODIFIED			(304)
   RC_USE_PROXY				(305)

   RC_BAD_REQUEST			(400)
   RC_UNAUTHORIZED			(401)
   RC_PAYMENT_REQUIRED			(402)
   RC_FORBIDDEN				(403)
   RC_NOT_FOUND				(404)
   RC_METHOD_NOT_ALLOWED		(405)
   RC_NOT_ACCEPTABLE			(406)
   RC_PROXY_AUTHENTICATION_REQUIRED	(407)
   RC_REQUEST_TIMEOUT			(408)
   RC_CONFLICT				(409)
   RC_GONE				(410)
   RC_LENGTH_REQUIRED			(411)
   RC_PRECONDITION_FAILED		(412)
   RC_REQUEST_ENTITY_TOO_LARGE		(413)
   RC_REQUEST_URI_TOO_LARGE		(414)
   RC_UNSUPPORTED_MEDIA_TYPE		(415)

   RC_INTERNAL_SERVER_ERROR		(500)
   RC_NOT_IMPLEMENTED			(501)
   RC_BAD_GATEWAY			(502)
   RC_SERVICE_UNAVAILABLE		(503)
   RC_GATEWAY_TIMEOUT			(504)
   RC_HTTP_VERSION_NOT_SUPPORTED	(505)

=cut

#####################################################################


require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(is_info is_success is_redirect is_error status_message);
@EXPORT_OK = qw(is_client_error is_server_error);

# Note also addition of mnemonics to @EXPORT below

my %StatusCode = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Moved Temporarily',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
);

my $mnemonicCode = '';
my ($code, $message);
while (($code, $message) = each %StatusCode) {
    # create mnemonic subroutines
    $message =~ tr/a-z \-/A-Z__/;
    $mnemonicCode .= "sub RC_$message () { $code }\t";
    # make them exportable
    $mnemonicCode .= "push(\@EXPORT, 'RC_$message');\n";
}
# warn $mnemonicCode; # for development
eval $mnemonicCode; # only one eval for speed
die if $@;

=head1 FUNCTIONS

The following additional functions are provided.  Most of them are
exported by default.

=over 4

=item status_message($code)

The status_message() function will translate status codes to human
readable strings. The string is the same as found in the constant
names above.

=cut

sub status_message ($)
{
    return undef unless exists $StatusCode{$_[0]};
    $StatusCode{$_[0]};
}

=item is_info($code)

Return TRUE if C<$code> is an I<Informational> status code.

=item is_success($code)

Return TRUE if C<$code> is a I<Successful> status code.

=item is_redirect($code)

Return TRUE if C<$code> is a I<Redirection> status code.

=item is_error($code)

Return TRUE if C<$code> is an I<Error> status code.  The function
return TRUE for both client error or a server error status codes.

=item is_client_error($code)

Return TRUE if C<$code> is an I<Client Error> status code.  This
function is B<not> exported by default.

=item is_server_error($code)

Return TRUE if C<$code> is an I<Server Error> status code.   This
function is B<not> exported by default.

=back

=cut

sub is_info         ($) { $_[0] >= 100 && $_[0] < 200; }
sub is_success      ($) { $_[0] >= 200 && $_[0] < 300; }
sub is_redirect     ($) { $_[0] >= 300 && $_[0] < 400; }
sub is_error        ($) { $_[0] >= 400 && $_[0] < 600; }
sub is_client_error ($) { $_[0] >= 400 && $_[0] < 500; }
sub is_server_error ($) { $_[0] >= 500 && $_[0] < 600; }

1;
