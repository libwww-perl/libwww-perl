#
# $Id: Status.pm,v 1.10 1995/08/09 11:29:32 aas Exp $

package HTTP::Status;

=head1 NAME

HTTP::Status - HTTP Status code processing

=head1 SYNOPSIS

 use HTTP::Status;

 if ($rc != RC_OK) { 
     print statusMessage($rc), "\n";
 }

 if (isSuccess($rc)) { ... }
 if (isError($rc)) { ... }
 if (isRedirect($rc)) { ... }

=head1 DESCRIPTION

HTTP::Status is a library of routines for manipulating
HTTP Status Codes for L<libwww-perl>.

The following functions can be used as mnemonic status codes:

   RC_OK
   RC_CREATED
   RC_ACCEPTED
   RC_NON_AUTHORITATIVE_INFORMATION
   RC_NO_CONTENT
   RC_MULTIPLE_CHOICES
   RC_MOVED_PERMANENTLY
   RC_MOVED_TEMPORARILY
   RC_SEE_OTHER
   RC_NOT_MODIFIED
   RC_BAD_REQUEST
   RC_UNAUTHORIZED
   RC_PAYMENT_REQUIRED
   RC_FORBIDDEN
   RC_NOT_FOUND
   RC_METHOD_NOT_ALLOWED
   RC_NONE_ACCEPTABLE
   RC_PROXY_AUTHENTICATION_REQUIRED
   RC_REQUEST_TIMEOUT
   RC_CONFLICT
   RC_GONE
   RC_AUTHORIZATION_NEEDED
   RC_INTERNAL_SERVER_ERROR
   RC_NOT_IMPLEMENTED
   RC_BAD_GATEWAY
   RC_SERVICE_UNAVAILABLE
   RC_GATEWAY_TIMEOUT

The C<statusMessage()> function will translate status codes to human
readable strings.

The C<isSuccess()>, C<isError()>, and C<isRedirect()> functions will
return a true value if the passed status code indicates success, and
error, or a redirect respectively.

=cut

#####################################################################


require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(isSuccess isError isRedirect statusMessage);

# Note also addition of mnemonics to @EXPORT below

my %StatusCode = (
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Moved Temporarily',
    303 => 'See Other',
    304 => 'Not Modified',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'None Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Authorization Refused',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
);

my $mnemonicCode = '';
my ($code, $message);
while (($code, $message) = each %StatusCode) {
    # create mnemonic subroutines
    $message =~ tr/a-z \-/A-Z__/;
    $mnemonicCode .= "sub RC_$message { $code }\t";
    # make them exportable
    $mnemonicCode .= "push(\@EXPORT, 'RC_$message');\n";
}
# warn $mnemonicCode; # for development
eval $mnemonicCode; # only one eval for speed
die if $@;
undef $mnemonicCode;


=head2 statusMessage($code)

Return user friendly error message for status code C<$code>

=cut

sub statusMessage
{
    return undef unless exists $StatusCode{$_[0]};
    $StatusCode{$_[0]};
}


=head2 isSuccess($code)

Return a true value if C<$code> is a Success status code

=head2 isRedirect($code)

Return a true value if C<$code> is a Redirect status code

=head2 isError($code)

Return a true value if C<$code> is an Error status code

=cut

sub isSuccess  { $_[0] >= 200 && $_[0] < 300; }
sub isRedirect { $_[0] >= 300 && $_[0] < 400; }
sub isError    { $_[0] >= 400 && $_[0] < 600; }


1;
