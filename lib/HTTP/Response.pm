#
# $Id: Response.pm,v 1.18 1996/04/09 15:44:21 aas Exp $

package HTTP::Response;


=head1 NAME

HTTP::Response - Class encapsulating HTTP Responses

=head1 SYNOPSIS

 require HTTP::Response;

=head1 DESCRIPTION

C<HTTP::Response> is a class encapsulating HTTP style responses,
consisting of a response line, a MIME header, and usually
content. Note that the LWP library also uses this HTTP style responses
for non-HTTP protocols.

Instances of this class are usually created by calling the
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
push_header(), remove_header() headers_as_string() and content().  See
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
response.  It might not be the same request that was passed to the
$ua->request() method, because there might have been redirects and
authorization retries.

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

  1.  Embedded in the document content, for instance <BASE HREF="...">
  2.  A "Base:" header in the response
  3.  The URL used to request this response

=cut

sub base
{
    my $self = shift;
    my $base = undef;
    if ($self->content_type eq 'text/html') {
	# Look for the <BASE HREF='...'> tag
	# XXX: Should really use the HTML::Parse module to get this
	# right. The <BASE> tag could be commented out, which we are
	# not able to handle with this simple regexp.
	if ($self->{'_content'} =~ /<\s*base\s+href=([^\s>]+)/i) {
	    $base = $1;
	    $base =~ s/^(["'])(.*)\1$/$2/;  #" get rid of any quoting
	    return $base;
	}
    }
    $base = $self->header('Base') unless $base;
    $base = $self->request->url unless $base;
    $base;
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


=head2 error_as_HTML()

Return string with a complete HTML document indicating
what error occurred

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
