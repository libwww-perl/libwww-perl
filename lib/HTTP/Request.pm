#
# $Id: Request.pm,v 1.9 1995/07/16 07:24:01 aas Exp $

package LWP::Request;

=head1 NAME

LWP::Request - Class encapsulating HTTP Requests

=head1 SYNOPSIS

 require LWP::Request;
 $request = new LWP::Request('GET', 'http://www.oslonett.no/');
 
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

=head1 METHODS

C<LWP::Request> is a subclass of C<LWP::Message> and therefore
inherits its methods.  The inherited methods are C<header>,
C<pushHeader>, C<removeHeader> C<headerAsString> and C<content>.  See
L<LWP::Message> for details.

=cut

require LWP::Message;
@ISA = qw(LWP::Message);
require URI::URL;

=head2 new($method, $url, [$header, [$content]])

Constructs a new C<LWP::Request> object describing a request on the
object C<$url> using method C<$method>.  The C<$url> argument can be
either a string, or a reference to a C<URI::URL> object.  The $header
argument should be a reference to a MIMEheader.

 $request = new LWP::Request('GET', 'http://www.oslonett.no/');

=cut

sub new
{
    my($class, $method, $url, $header, $content) = @_;
    my $self = bless new LWP::Message $header, $content;
    $self->method($method);
    $self->url($url);
    $self;
}


sub clone
{
    my $self = shift;
    my $clone = bless $self->LWP::Message::clone;
    $clone->method($self->method);
    $clone->url($self->url);
    $clone;
}


=head2 method([$val])

=head2 url([$val])

These methods provide public access to the member variables containing
respectively the method of the request and the URL object of the
request.

If an argument is given the member variable is given that as its new
value. If no argument is given the value is not touched. In either
case the previous value is returned.

=cut

sub method  { shift->_elem('_method', @_); }

sub url
{
    my($self, $url) = @_;
    if (defined $url) {
        if (ref $url) {
            $url = $url->abs;
        } else {
            $url = new URI::URL($url);
        }
    }
    $self->_elem('_url', $url);
}


=head2 asString()

Method returning a textual representation of the request.
Mainly useful for debugging purposes. It takes no arguments.

=cut

sub asString
{
    my $self = shift;
    my @result = ("--- $self ---");
    my $url = $self->url;
    $url = (defined $url) ? $url->as_string : "[NO URL]";
    push(@result, $self->method . " $url");
    push(@result, $self->headerAsString);
    my $content = $self->content;
    if ($content) {
        push(@result, $self->content);
    }
    push(@result, ("-" x 35));
    join("\n", @result, "");
}

1;
