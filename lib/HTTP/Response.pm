#
# $Id: Response.pm,v 1.11 1995/08/17 13:58:49 aas Exp $

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

Instances of this class are usually created by the C<request()> method
of an C<LWP::UserAgent> object:

 ...
 $response = $ua->request($request)
 if ($response->isSuccess) {
     print $response->content;
 } else {
     print $response->errorAsHTML;    
 }

=head1 METHODS

C<HTTP::Response> is a subclass of C<HTTP::Message> and therefore
inherits its methods.  The inherited methods are C<header>,
C<pushHeader>, C<removeHeader> C<headerAsString> and C<content>.  See
L<HTTP::Message> for details.

=cut


require HTTP::Message;
@ISA = qw(HTTP::Message);

require HTTP::Status;


=head2 new($rc [, $msg])

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

=head2 code([$code])

=head2 message([$message])

=head2 request([$request])

=head2 previous([$previousResponse])

These methods provide public access to the member variables.  The
first two containing respectively the response code and the message
of the response.

The request attribute is used to record the request that gave this
response. You should for instance access the base URL of an document
like this: C<$response->request->url;>.

The previous attribute is used to link together chains of responses.
You get chains of responses if the first response is redirect or
unauthorized.

=cut

sub code      { shift->_elem('_rc',      @_); }
sub message   { shift->_elem('_msg',     @_); }
sub previous  { shift->_elem('_previous',@_); }
sub request   { shift->_elem('_request', @_); }


=head2 asString()

Method returning a textual representation of the request.  Mainly
useful for debugging purposes. It takes no arguments.

=cut

sub asString
{
    require HTTP::Status;
    my $self = shift;
    my @result = ("--- $self ---");
    my $code = $self->code;
    push(@result, "RC: $code (" . HTTP::Status::statusMessage($code) . ")" );
    push(@result, 'Message: ' . $self->message);
    push(@result, '');
    push(@result, $self->headerAsString);
    my $content = $self->content;
    if ($content) {
        push(@result, $self->content);
    }
    push(@result, ("-" x 35));
    join("\n", @result, "");
}

=head2 isSuccess

=head2 isRedirect

=head2 isError

These methods indicate if the response was sucessful, a redirection,
or an error.

=cut

sub isRedirect { HTTP::Status::isRedirect(shift->code); }
sub isSuccess  { HTTP::Status::isSuccess(shift->code);  }
sub isError    { HTTP::Status::isError(shift->code);    }


=head2 errorAsHTML()

Return string with a complete HTML document indicating
what error occurred

=cut

sub errorAsHTML
{
    my $self = shift;
    my $msg = $self->{'_msg'} || 'Unknown';
    my $content = $self->content || '';
    if (defined $content and length $content) {
        return $content;
    }
    else {
    my $title = 'An Error Occurred';
    return <<EOM;
<HTML>
<HEAD>
<TITLE>
$title
</TITLE>
</HEAD>
<BODY>
<H1>$title</h1>
$msg
</BODY>
</HTML>
EOM
    }
}

1;
