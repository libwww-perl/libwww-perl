#
# $Id: Request.pm,v 1.17 1996/09/18 12:15:16 aas Exp $

package HTTP::Request;

=head1 NAME

HTTP::Request - Class encapsulating HTTP Requests

=head1 SYNOPSIS

 require HTTP::Request;
 $request = new HTTP::Request 'GET', 'http://www.oslonett.no/';

=head1 DESCRIPTION

C<HTTP::Request> is a class encapsulating HTTP style requests,
consisting of a request line, a MIME header, and optional
content. Note that the LWP library also uses this HTTP style requests
for non-HTTP protocols.

Instances of this class are usually passed to the C<request()> method
of an C<LWP::UserAgent> object:

 $ua = new LWP::UserAgent;
 $request = new HTTP::Request 'http://www.oslonett.no/';
 $response = $ua->request($request);

=head1 METHODS

C<HTTP::Request> is a subclass of C<HTTP::Message> and therefore
inherits its methods.  The inherited methods are header(),
push_header(), remove_header(), headers_as_string() and content().
See L<HTTP::Message> for details.

=cut

require HTTP::Message;
@ISA = qw(HTTP::Message);

use URI::URL ();
use strict;

=head2 $r = new HTTP::Request $method, $url, [$header, [$content]]

Constructs a new C<HTTP::Request> object describing a request on the
object C<$url> using method C<$method>.  The C<$url> argument can be
either a string, or a reference to a C<URI::URL> object.  The $header
argument should be a reference to a HTTP::Headers object.

 $request = new HTTP::Request 'GET', 'http://www.oslonett.no/';

=cut

sub new
{
    my($class, $method, $url, $header, $content) = @_;
    my $self = bless new HTTP::Message $header, $content;
    $self->method($method);
    $self->url($url);
    $self;
}


sub clone
{
    my $self = shift;
    my $clone = bless $self->HTTP::Message::clone;
    $clone->method($self->method);
    $clone->url($self->url);
    $clone;
}


=head2 $r->method([$val])

=head2 $r->url([$val])

These methods provide public access to the member variables containing
respectively the method of the request and the URL object of the
request.

If an argument is given the member variable is given that as its new
value. If no argument is given the value is not touched. In either
case the previous value is returned.

The url() method accept both a reference to a URI::URL object and a
string as its argument.  If a string is given, then it should be
parseable as an absolute URL.

=cut

sub method  { shift->_elem('_method', @_); }

sub url
{
    my $self = shift;
    my($url) = @_;
    if (@_) {
	if (!defined $url) {
	    # that's ok
	} elsif (ref $url) {
	    $url = $url->abs;
	} else {
	    eval {  $url = URI::URL->new($url); };
	    $url = undef if $@;
	}
    }
    $self->_elem('_url', $url);
}

*uri = \&url;  # this is the same for now

=head2 $r->as_string()

Method returning a textual representation of the request.
Mainly useful for debugging purposes. It takes no arguments.

=cut

sub as_string
{
    my $self = shift;
    my @result = ("--- $self ---");
    my $url = $self->url;
    $url = (defined $url) ? $url->as_string : "[NO URL]";
    push(@result, $self->method . " $url");
    push(@result, $self->headers_as_string);
    my $content = $self->content;
    if ($content) {
	push(@result, $self->content);
    }
    push(@result, ("-" x 35));
    join("\n", @result, "");
}

1;
