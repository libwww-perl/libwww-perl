#
# $Id: Simple.pm,v 1.3 1995/07/11 22:41:28 aas Exp $

=head1 NAME

get, head, getprint, getstore, mirror - Procedural LWP interface

=head1 SYNOPSIS

 perl -e 'use LWP::Simple; getprint("http://www.oslonett.no");'

 use LWP::Simple;
 $content = get("http://www.oslonett.no/")

=head1 DESCRIPTION

This interface is intended for those who want a simplified view of the
LWP library.  This interface should also be suitable for one-liners.

A few convenience methods cover frequent uses: the C<getAndPrint>
and C<getAndStore> methods print and save the results of a GET
request.  The message is printed on STDERR unless succesful response.
Both routines returns a C<LWP::Reponse> object.

The C<get> method returns the content of a ducument. It returns undef
in case of errors.

=cut


package LWP::Simple;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get head getprint getstore mirror);


require LWP::UserAgent;
$ua = new LWP::UserAgent;  # we create a global UserAgent object

use LWP::Date qw(str2time);
use Carp;


=head2 get($url)

Get a document.  Returns the document is successful.  Returns 'undef' if it
fails.

=cut

sub get {
    my($url) = @_;
    LWP::Debug::trace('()');

    my $request = new LWP::Request('GET', $url);
    my $response = $ua->request($request);

    return $response->content if $response->isSuccess;
    return undef;
}

=head2 head($url)

Get document headers. Returns the following values if successful:
($content_type, $document_length, $modified_time, $expires, $server)

Returns 'undef' if it fails.

=cut

sub head {
    my($url) = @_;
    LWP::Debug::trace('()');

    my $request = new LWP::Request('HEAD', $url);
    my $response = $ua->request($request);

    if ($response->isSuccess) {
	return ($response->header('Content-Type'),
	        $response->header('Content-Length'),
                str2time($response->header('Last-Modified')),
                str2time($response->header('Expires')),#XXX: Verify header name
        	$response->header('Server'),
               );
    } else {
        return undef;
    }
}

=head2 getprint($url)

Get and print a document identified by a URL. The document is printet
on STDOUT. The error message is printed on STDERR if it fails. The
return value is a reference to the LWP::Response object.

=cut

sub getprint {
    my($url) = @_;
    LWP::Debug::trace('()');

    my $request = new LWP::Request('GET', $url);
    my $response = $ua->request($request);

    if ($response->isSuccess) {
        print $response->content;
    } else {
        print STDERR $response->errorAsHTML;
    }
    $response->code;
}


=head2 getstore($url, $file)

Get and store a document identified by a URL. The return value is a
reference to the LWP::Response object. You should check this for
success.

=cut

sub getstore {
    my($url, $file) = @_;
    croak("getAndStore needs two arguments") unless @_ == 2;

    LWP::Debug::trace('()');

    my $request = new LWP::Request('GET', $url);
    my $response = $ua->request($request, $file);

    $response->code;
}


=head2 mirror($url, $file)

Get and store a document identified by a URL,
using If-modified-since, and checking of the content-length.
Returns response code.

=cut

sub mirror {
    croak("mirror needs two arguments") unless @_ == 2;

    my($url, $file) = @_;
    my $response = $ua->mirror($url, $file);
    $response->code;
}



