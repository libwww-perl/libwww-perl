#
# $Id: Response.pm,v 1.6 1995/07/14 00:31:03 aas Exp $

package LWP::Response;


=head1 NAME

LWP::Response - Class encapsulating HTTP Responses

=head1 SYNOPSIS

 require LWP::Response;

=head1 DESCRIPTION

C<LWP::Response> is a class encapsulating HTTP style responses,
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

C<LWP::Response> is a subclass of C<LWP::Message> and therefore
inherits its methods.  The inherited methods are C<header>,
C<pushHeader>, C<removeHeader> C<headerAsString> and C<content>.  See
L<LWP::Message> for details.

=cut


require LWP::Message;
@ISA = qw(LWP::Message);


=head2 new($rc [, $msg])

Constructs a new C<LWP::Response> object describing a response with
response code C<$rc> and optional message C<$msg>

=cut

sub new
{
    my($class, $rc, $msg) = @_;
    my $self = bless new LWP::Message;
    $self->code($rc);
    $self->message($msg);
    $self;
}


sub clone
{
    my $self = shift;
    my $clone = bless $self->LWP::Message::clone;
    $clone->code($self->code);
    $clone->message($self->message);
    $clone;
    
}

=head2 code([$code])

=head2 message([$message]}

These methods provide public access to the member variables containing
respectively the response code and the message of the response

=cut

sub code      { shift->_elem('_rc',  @_); }
sub message   { shift->_elem('_msg', @_); }


=head2 asString()

Method returning a textual representation of the request.  Mainly
useful for debugging purposes. It takes no arguments.

=cut

sub asString
{
    require LWP::StatusCode;
    my $self = shift;
    my @result = ("--- $self ---");
    my $code = $self->code;
    push(@result, "RC: $code (" . LWP::StatusCode::message($code) . ")" );
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

sub isRedirect { LWP::StatusCode::isRedirect(shift->code); }
sub isSuccess  { LWP::StatusCode::isSuccess(shift->code);  }
sub isError    { LWP::StatusCode::isError(shift->code);    }


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
