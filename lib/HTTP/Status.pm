#
# $Id: Status.pm,v 1.3 1995/07/11 13:21:05 aas Exp $

package LWP::StatusCode;

=head1 NAME

LWP::StatusCode - HTTP Status code processing

=head1 SYNOPSIS

 use LWP::StatusCode;

 if ($rc != RC_OK) { 
     print statusMessage($rc), "\n";
 }

 if (isSuccess($rc)) { ... }
 if (isError($rc)) { ... }
 if (isRedirect($rc)) { ... }

=head1 DESCRIPTION

LWP::StatusCode is a library of routines for manipulating
HTTP Status Codes for L<lwp>.

The C<RC_*> rountines can be used as mnemonic status codes.
These are constructed by taking the human readable string,
converting it to upper case and converting spaces to '_',
and prepending 'RC_';

The C<message> function will translate status codes to human
readable strings.

The C<isSuccess>, C<isError>, and C<isRedirect> functions will return
a true value if the passed status code indicates success, and error,
or a redirect respectively.

=cut

#####################################################################


require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(isSuccess isError isRedirect);

# Note also addition of mnemonics to @EXPORT_OK below

my %StatusCode = (
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Provisional Information',
    204 => 'No Content',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Moved Temporarily',
    303 => 'Method',
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
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Tieout',
);

my $mnemonicCode = '';
my ($code, $message);
while (($code, $message) = each %StatusCode) {
    # create mnemonic subroutines
    $message =~ tr/a-z /A-Z_/;
    $mnemonicCode .= "sub RC_$message { $code }\t";
    # make them exportable
    $mnemonicCode .= "push(\@EXPORT_OK, 'RC_$message');\n";
}
# warn $mnemonicCode; # for development
eval $mnemonicCode; # only one eval for speed
undef $mnemonicCode;


=head2 message($code)

Return user friendly error message for status code C<$code>

=cut

sub message {
    return undef unless exists $StatusCode{$_[0]};
    $StatusCode{$_[0]};
}


=head2 isSuccess($code)

Return TRUE if C<$code> is a Success status code

=cut

sub isSuccess {
    $_[0] >= 200 && $_[0] < 300;
}


=head2 isRedirect($code)

Return TRUE if C<$code> is a Redirect status code

=cut

sub isRedirect {
    $_[0] >= 300 && $_[0] < 400;
}


=head2 isError($code)

Return TRUE if C<$code> is an Error status code

=cut

sub isError {
    $_[0] >= 400 && $_[0] < 600;
}


1;
