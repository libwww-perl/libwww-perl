#
# $Id: Status.pm,v 1.18 1996/07/17 11:39:25 aas Exp $

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

HTTP::Status is a library of routines for defining and classification
of HTTP status codes for libwww-perl.  Status codes are used to encode
the overall outcome of a HTTP response message.  Codes correspond to
those defined in E<lt>draft-ietf-http-v11-spec-06>.

The following functions can be used as mnemonic status code names:

   RC_CONTINUE
   RC_SWITCHING_PROTOCOLS
   RC_OK
   RC_CREATED
   RC_ACCEPTED
   RC_NON_AUTHORITATIVE_INFORMATION
   RC_NO_CONTENT
   RC_RESET_CONTENT
   RC_PARTIAL_CONTENT
   RC_MULTIPLE_CHOICES
   RC_MOVED_PERMANENTLY
   RC_MOVED_TEMPORARILY
   RC_SEE_OTHER
   RC_NOT_MODIFIED
   RC_USE_PROXY
   RC_BAD_REQUEST
   RC_UNAUTHORIZED
   RC_PAYMENT_REQUIRED
   RC_FORBIDDEN
   RC_NOT_FOUND
   RC_METHOD_NOT_ALLOWED
   RC_NOT_ACCEPTABLE
   RC_PROXY_AUTHENTICATION_REQUIRED
   RC_REQUEST_TIMEOUT
   RC_CONFLICT
   RC_GONE
   RC_LENGTH_REQUIRED
   RC_PRECONDITION_FAILED
   RC_REQUEST_ENTITY_TOO_LARGE
   RC_REQUEST_URI_TOO_LARGE
   RC_UNSUPPORTED_MEDIA_TYPE
   RC_INTERNAL_SERVER_ERROR
   RC_NOT_IMPLEMENTED
   RC_BAD_GATEWAY
   RC_SERVICE_UNAVAILABLE
   RC_GATEWAY_TIMEOUT
   RC_HTTP_VERSION_NOT_SUPPORTED

The status_message() function will translate status codes to human
readable strings.

The is_info(), is_success(), is_error(), and is_redirect() functions
will return a TRUE value if the passed status code indicates success,
and error, or a redirect respectively.

=cut

#####################################################################


require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(is_info is_success is_redirect is_error status_message);

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


=head2 status_message($code)

Return user friendly error message for status code C<$code>

=cut

sub status_message ($)
{
    return undef unless exists $StatusCode{$_[0]};
    $StatusCode{$_[0]};
}

=head2 is_info($code)

Return TRUE if C<$code> is an Informational status code

=head2 is_success($code)

Return TRUE if C<$code> is a Successful status code

=head2 is_redirect($code)

Return TRUE if C<$code> is a Redirection status code

=head2 is_error($code)

Return TRUE if C<$code> is an Error status code

=cut

sub is_info         ($) { $_[0] >= 100 && $_[0] < 200; }
sub is_success      ($) { $_[0] >= 200 && $_[0] < 300; }
sub is_redirect     ($) { $_[0] >= 300 && $_[0] < 400; }
sub is_error        ($) { $_[0] >= 400 && $_[0] < 600; }
sub is_client_error ($) { $_[0] >= 400 && $_[0] < 500; }
sub is_server_error ($) { $_[0] >= 500 && $_[0] < 600; }

1;
