#
# $Id: Request.pm,v 1.5 1995/07/11 22:42:10 aas Exp $

package LWP::Request;

require LWP::Message;
@ISA = qw(LWP::Message);

=head1 NAME

LWP::Request - Class encapsulating HTTP Requests

=head1 SYNOPSIS

 require LWP::Request;
 $request = new LWP::Request('http://www.oslonett.no/');
 
=head1 DESCRIPTION

C<LWP::Request> is a class encapsulating HTTP style requests,
consisting of a request line, a MIME header, and optional
content. Note that the LWP library also uses this HTTP style requests
for non-HTTP protocols.

Instances of this class are usually passed to the C<request()> method
of an C<LWP::UserAgent> object:

 $ua = new LWP::UserAgent;
 $request = new LWP::Request('http://www.oslonett.no/');  
 $response = $ua->request($request);
 ...

=head1 METHODS and FUNCTIONS

=cut

require LWP::MIMEheader;
require LWP::Debug;
require URI::URL;

use Carp;

#####################################################################
#
# I N I T  S E C T I O N
#
#####################################################################

# "Good Practice" order of HTTP message headers:
# General-Header, Request-Header, Entity-Header.
# (From draft-ietf-http-v10-spec-00.ps)

my @header_order = qw( 
   Date Forwarded Message-ID MIME-Version

   Accept Accept-Charset Accept-Encoding Accept-Language
   Authorization From If-Modified-Since Praga Referer User-Agent
   
   Content-Encoding Content-Language Content-Length
   Content-Transfer-Encoding Content-Type Derived-From
   Expires Last-Modified Link Location Title URI-Header
   Version
);


#####################################################################
#
# P U B L I C  M E T H O D S  S E C T I O N
#
#####################################################################

=head2 new($method, $url)

Constructs a new C<LWP::Request> object describing a request on the
object C<$url> using method C<$method>.  The C<$url> argument can be
either a string, or a reference to a C<URI::URL> object.

 $request = new LWP::Request('GET', 'http://www.oslonett.no/');

=cut

sub new {
    my($class, $method, $url, $content) = @_;
    unless (ref $url) {
	$url = new URI::URL($url);
    } else {
	$url = $url->abs;
    }

    bless {
        '_method'  => $method,
        '_url'     => $url,
        '_content' => $content,
        '_header'  => new LWP::MIMEheader,
    }, $class;
}

=head2 method([$val])

=head2 url([$val])

=head2 content([$val])

These methods provide public access to the member variables containing
respectively the method of the request, the URL of the object of the
request, and the content of the request.

If an argument is given the member variable is given that as its new
value. If no argument is given the value is not touched. In either
case the previous value is returned.

=cut

sub method  { my $self = shift; $self->_elem('_method',  @_); }
sub content { my $self = shift; $self->_elem('_content', @_); }
sub url     { my $self = shift; $self->_elem('_url', @_); }


=head2 header(...)

=head2 pushHeader(...)

=head2 headerAsMIME()

These methods provide easy access to the fields for the request
header. Usual use as follows:

 $request->header('Accept', ['text/html', 'text/plain']);
 $request->pushHeader('Accept', 'image/jpeg');

 print $socket $request->headerAsMIME;

=cut

# forward these to the header member variable
sub headers      { shift->{'_header'}; }
sub header       { shift->{'_header'}->header(@_) }
sub pushHeader   { shift->{'_header'}->pushHeader(@_) }

sub headerAsMIME {
    my($self) = shift; 
    $self->{'_header'}->asMIME(@_, "\r\n", \@header_order);
}


=head2 as_string()

Method returning a textual representation of the request.
Mainly useful for debugging purposes. It takes no arguments.

=cut

sub as_string {
    my $self = shift;
    my $result = "LWP::Request::as_string($self):\n";
    $result .= 'Method: '   . $self->_strElem('_method')   . "\n";
    $result .= 'URL: '      . $self->_strElem('_url')      . "\n";
    $result .= "Header:\n"  . $self->{'_header'}->as_string ."\n";
    $result .= "Content:\n" . $self->_strElem('_content')  . "\n";
    $result .= "\n";
    $result;
}

1;
