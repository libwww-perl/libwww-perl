#
# $Id: Response.pm,v 1.19 1996/05/26 10:40:27 aas Exp $

package HTTP::Response;


=head1 NAME

HTTP::Response - Class encapsulating HTTP Responses

=head1 SYNOPSIS

 require HTTP::Response;

=head1 DESCRIPTION

The C<HTTP::Response> class encapsulate HTTP style responses.  A
response consist of a response line, some headers, and a (potential
empty) content. Note that the LWP library will use HTTP style
responses also for non-HTTP protocol schemes.

Instances of this class are usually created and returned by the
C<request()> method of an C<LWP::UserAgent> object:

 ...
 $response = $ua->request($request)
 if ($response->is_success) {
     print $response->content;
 } else {
     print $response->error_as_HTML;
 }

=head1 METHODS

C<HTTP::Response> is a subclass of C<HTTP::Message> and therefore
inherits its methods.  The inherited methods are header(),
push_header(), remove_header(), headers_as_string(), and content().
The header convenience methods are also available.  See
L<HTTP::Message> for details.

=cut


require HTTP::Message;
@ISA = qw(HTTP::Message);

use HTTP::Status ();


=head2 $r = new HTTP::Response ($rc [, $msg])

Constructs a new C<HTTP::Response> object describing a response with
response code C<$rc> and optional message C<$msg>

=cut

sub new
{
    my($class, $rc, $msg) = @_;
    my $self = bless new HTTP::Message;
    $self->code($rc);
    $self->message($msg);
    $self;
}


sub clone
{
    my $self = shift;
    my $clone = bless $self->HTTP::Message::clone;
    $clone->code($self->code);
    $clone->message($self->message);
    $clone->request($self->request->clone) if $self->request;
    # we don't clone previous
    $clone;
}

=head2 $r->code([$code])

=head2 $r->message([$message])

=head2 $r->request([$request])

=head2 $r->previous([$previousResponse])

These methods provide public access to the member variables.  The
first two containing respectively the response code and the message
of the response.

The request attribute is a reference the request that gave this
response.  It does not have to be the same request as passed to the
$ua->request() method, because there might have been redirects and
authorization retries in between.

The previous attribute is used to link together chains of responses.
You get chains of responses if the first response is redirect or
unauthorized.

=cut

sub code      { shift->_elem('_rc',      @_); }
sub message   { shift->_elem('_msg',     @_); }
sub previous  { shift->_elem('_previous',@_); }
sub request   { shift->_elem('_request', @_); }

=head2 $r->base

Returns the base URL for this response.  The base URL can come from 3
sources:

=over 4

=item 1.

Embedded in the document content, for instance <BASE HREF="...">
in HTML documents.

=item 2.

A "Base:" header in the response


=item 3.

The URL used to request this response

=back

A base URL embedded in the document will initialize the "Base:" header
in the response object, which means that only the last 2 sources are
checked by this method.

=cut

sub base
{
    my $self = shift;
    $self->header('Base') ||  $self->request->url;
}


=head2 $r->as_string()

Method returning a textual representation of the request.  Mainly
useful for debugging purposes. It takes no arguments.

=cut

sub as_string
{
    require HTTP::Status;
    my $self = shift;
    my @result = ("--- $self ---");
    my $code = $self->code;
    push(@result, "RC: $code (" . HTTP::Status::status_message($code) . ")" );
    push(@result, 'Message: ' . $self->message);
    push(@result, '');
    push(@result, $self->headers_as_string);
    my $content = $self->content;
    if ($content) {
	push(@result, $self->content);
    }
    push(@result, ("-" x 35));
    join("\n", @result, "");
}

=head2 $r->is_info

=head2 $r->is_success

=head2 $r->is_redirect

=head2 $r->is_error

These methods indicate if the response was informational, sucessful, a
redirection, or an error.

=cut

sub is_info     { HTTP::Status::is_info     (shift->{'_rc'}); }
sub is_success  { HTTP::Status::is_success  (shift->{'_rc'}); }
sub is_redirect { HTTP::Status::is_redirect (shift->{'_rc'}); }
sub is_error    { HTTP::Status::is_error    (shift->{'_rc'}); }


=head2 $r->error_as_HTML()

Return a string containing a complete HTML document indicating what
error occurred.  This method should only be called when $r->is_error
is TRUE.

=cut

sub error_as_HTML
{
    my $self = shift;
    my $msg = $self->{'_msg'} || 'Unknown';
    my $title = 'An Error Occurred';
    my $code = $self->code;
    return <<EOM;
<HTML>
<HEAD>
<TITLE>
$title
</TITLE>
</HEAD>
<BODY>
<H1>$title</h1>
$code - $msg
</BODY>
</HTML>
EOM
}

1;
