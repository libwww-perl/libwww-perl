#
# $Id: Simple.pm,v 1.1 1995/06/14 10:58:06 aas Exp $
#

package LWP::Simple;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get head getprint getstore mirror);


require LWP::UserAgent;
$ua = new LWP::UserAgent;  # we create a global UserAgent object

use LWP::Date qw(str2time);
use Carp;


=head1 get($url)

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

=head1 head($url)

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

=head1 getprint($url)

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
    $response;
}

=head1 getstore($url, $file)

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

    $response;
}

=head1 mirror($url, $file)

Get and store a document identified by a URL,
using If-modified-since, and checking of the content-length.
Returns response.

=cut

sub mirror {
    my($url, $file) = @_;
    croak("mirror needs two arguments") unless @_ == 2;

    LWP::Debug::trace('()');

    my $request = new LWP::Request('GET', $url);

    my($ST_SIZE, $ST_MTIME) = (7, 9);
    if (-e $file) {
	my($mtime) = (stat($file))[$ST_MTIME];
	if($mtime) {
	    $request->header('If-Modified-Since',
			     &LWP::Date::time2str($mtime));
	}
    }
    my $tmpfile = "$file-$$";

    my $response = $ua->request($request, $tmpfile);
    if ($response->isSuccess) {
	
	my $file_length = (stat($tmpfile))[$ST_MTIME];
	my($content_length) = $response->header('Content-length');
    
	if (defined $content_length and $file_length < $content_length) {
	    unlink($tmpfile);
	    die "Transfer truncated: " .
		"only $file_length out of $content_length bytes received\n";
	}
	elsif (defined $content_length and $file_length > $content_length) {
	    unlink($tmpfile);
	    die "Content-length mismatch: " .
		"expected $content_length bytes, got $file_length\n";
	}
	else {
	    # OK
	    rename($tmpfile, $file) or die
		"Cannot rename '$tmpfile' to '$file': $!\n";
	}
    }
    return $response;
}
