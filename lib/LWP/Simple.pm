#
# $Id: Simple.pm,v 1.9 1995/08/09 11:33:04 aas Exp $

=head1 NAME

get, head, getprint, getstore, mirror - Procedural LWP interface

=head1 SYNOPSIS

 perl -e 'use LWP::Simple; getprint("http://www.oslonett.no");'

 use LWP::Simple;
 $content = get("http://www.oslonett.no/")
 if (mirror("http://www.oslonett.no/", "foo") == RC_NOT_MODIFIED) {
     ...
 }
 if (isSuccess(getprint("http://www.oslonett.no/"))) {
     ...
 }

=head1 DESCRIPTION

This interface is intended for those who want a simplified view of the
LWP library.  This interface should also be suitable for one-liners.

This following procedures are exported:

=over 3

=item get($url)

Gets a document.  Returns the document is successful.  Returns 'undef'
if it fails.

=item head($url)

Get document headers. Returns the following values if successful:
($content_type, $document_length, $modified_time, $expires, $server)

Returns 'undef' if it fails.

=item getprint($url)

Get and print a document identified by a URL. The document is printet
on STDOUT. The error message is printed on STDERR if it fails.
It returns the response code.

=item getstore($url, $file)

Gets a document identified by a URL and stores it in the file. It
returns the response code.

=item mirror($url, $file)

Get and store a document identified by a URL, using If-modified-since,
and checking of the content-length.  Returns response code.

=back

This modules also exports the HTTP::Status constants and
procedures.  These can be used when you check the response code from
C<getprint>, C<getstore> and C<mirror>.  The constants are:

   RC_OK
   RC_CREATED
   RC_ACCEPTED
   RC_NON_AUTHORATIVE_INFORMATION
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

The HTTP::Status procedures are:

=over 3

=item isSuccess($rc)

Check if response code indicated successfull request.

=item isError($rc)

Check if response code indicated that an error occured.

=back

The module will also export the $ua object if you insist.

=head1 SEE ALSO

L<LWP>, L<LWP::UserAgent>, L<get>, L<mirror>

=cut


package LWP::Simple;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get head getprint getstore mirror);  # note additions below
@EXPORT_OK = qw($ua);

# We also export everything from HTTP::Status
use HTTP::Status;
push(@EXPORT, @HTTP::Status::EXPORT);

require LWP::UserAgent;
$ua = new LWP::UserAgent;  # we create a global UserAgent object

use HTTP::Date qw(str2time);
use Carp;


sub get
{
    my($url) = @_;

    my $request = new HTTP::Request('GET', $url);
    my $response = $ua->request($request);

    return $response->content if $response->isSuccess;
    return undef;
}


sub head
{
    my($url) = @_;

    my $request = new HTTP::Request('HEAD', $url);
    my $response = $ua->request($request);

    if ($response->isSuccess) {
        return ($response->header('Content-Type'),
                $response->header('Content-Length'),
                str2time($response->header('Last-Modified')),
                str2time($response->header('Expires')),
                $response->header('Server'),
               );
    } else {
        return undef;
    }
}


sub getprint
{
    my($url) = @_;

    my $request = new HTTP::Request('GET', $url);
    my $response = $ua->request($request);

    if ($response->isSuccess) {
        print $response->content;
    } else {
        print STDERR $response->errorAsHTML;
    }
    $response->code;
}


sub getstore
{
    my($url, $file) = @_;
    croak("getstore needs two arguments") unless @_ == 2;

    my $request = new HTTP::Request('GET', $url);
    my $response = $ua->request($request, $file);

    $response->code;
}

sub mirror
{
    croak("mirror needs two arguments") unless @_ == 2;

    my($url, $file) = @_;
    my $response = $ua->mirror($url, $file);
    $response->code;
}

1;
