#
# $Id: Simple.pm,v 1.19 1996/07/23 19:29:24 aas Exp $

=head1 NAME

get, head, getprint, getstore, mirror - Procedural LWP interface

=head1 SYNOPSIS

 perl -MLWP::Simple -e 'getprint "http://www.sn.no"'

 use LWP::Simple;
 $content = get("http://www.sn.no/")
 if (mirror("http://www.sn.no/", "foo") == RC_NOT_MODIFIED) {
     ...
 }
 if (is_success(getprint("http://www.sn.no/"))) {
     ...
 }

=head1 DESCRIPTION

This interface is intended for those who want a simplified view of the
libwww-perl library.  This interface should also be suitable for
one-liners.  If you need more control or access to the header fields
in the requests sent and responses received you should use the full OO
interface provided by the LWP::UserAgent module.

This following functions are provided (and exported) by this module:

=over 3

=item get($url)

This function will get the document identified by the given URL.  The
get() function will return the document if successful or 'undef' if it
fails.  The $url argument can be either a simple string or a reference
to a URI::URL object.

You will not be able to examine the response code or response headers
(like I<Content-Type>) when you are accessing the web using this
function.  If you need this you should use the full OO interface.

=item head($url)

Get document headers. Returns the following values if successful:
($content_type, $document_length, $modified_time, $expires, $server)

Returns an empty list if it fails.

=item getprint($url)

Get and print a document identified by a URL. The document is printet
on STDOUT. The error message (formatted as HTML) is printed on STDERR
if the request fails.  The return value is the HTTP response code.

=item getstore($url, $file)

Gets a document identified by a URL and stores it in the file. The
return value is the HTTP response code.

=item mirror($url, $file)

Get and store a document identified by a URL, using
I<If-modified-since>, and checking of the I<Content-Length>.  Returns
the HTTP response code.

=back

This module also exports the HTTP::Status constants and
procedures.  These can be used when you check the response code from
getprint(), getstore() and mirror().  The constants are:

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

The HTTP::Status classification functions are:

=over 3

=item is_success($rc)

Check if response code indicated successfull request.

=item is_error($rc)

Check if response code indicated that an error occured.

=back

The module will also export the LWP::UserAgent object as C<$ua> if you
ask for it explicitly.

The user agent created by this module will identify itself as
"LWP::Simple/0.00" and will initialize its proxy defaults from the
environment (by calling $ua->env_proxy).

=head1 SEE ALSO

L<LWP>, L<LWP::UserAgent>, L<HTTP::Status>, L<request>, L<mirror>

=cut


package LWP::Simple;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get head getprint getstore mirror);  # note additions below
@EXPORT_OK = qw($ua);

# We also export everything from HTTP::Status
use HTTP::Status;
push(@EXPORT, @HTTP::Status::EXPORT);

require LWP;
require LWP::UserAgent;
use HTTP::Date qw(str2time);
use Carp;

$ua = new LWP::UserAgent;  # we create a global UserAgent object
$ua->agent("LWP::Simple/$LWP::VERSION");
$ua->env_proxy;


sub get ($)
{
    my($url) = @_;

    my $request = new HTTP::Request 'GET', $url;
    my $response = $ua->request($request);

    return $response->content if $response->is_success;
    return undef;
}


sub head ($)
{
    my($url) = @_;

    my $request = new HTTP::Request HEAD => $url;
    my $response = $ua->request($request);

    if ($response->is_success) {
	return $response unless wantarray;
	return ($response->header('Content-Type'),
		$response->header('Content-Length'),
		str2time($response->header('Last-Modified')),
		str2time($response->header('Expires')),
		$response->header('Server'),
	       );
    } else {
	return wantarray ? () : '';
    }
}


sub getprint ($)
{
    my($url) = @_;

    my $request = new HTTP::Request 'GET', $url;
    my $response = $ua->request($request);
    local($\) = ""; # ensure standard $OUTPUT_RECORD_SEPARATOR
    if ($response->is_success) {
	print $response->content;
    } else {
	print STDERR $response->error_as_HTML;
    }
    $response->code;
}


sub getstore ($$)
{
    my($url, $file) = @_;

    my $request = new HTTP::Request 'GET', $url;
    my $response = $ua->request($request, $file);

    $response->code;
}

sub mirror ($$)
{
    my($url, $file) = @_;
    my $response = $ua->mirror($url, $file);
    $response->code;
}

1;
