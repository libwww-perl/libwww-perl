#
# $Id: Response.pm,v 1.5 1995/07/13 15:41:34 aas Exp $

package LWP::Response;

require LWP::Message;
@ISA = qw(LWP::Message);

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

=head1 METHODS and FUNCTIONS

=cut

require LWP::MIMEheader;
require LWP::Debug;

use Carp;


#####################################################################
#
# P U B L I C  M E T H O D S  S E C T I O N
#
#####################################################################

=head2 new($rc [, $msg])

Constructs a new C<LWP::Response> object describing a response with
response code C<$rc> and optional message C<$msg>

=cut

sub new {
    my($class, $rc, $msg) = @_;
    bless {
        '_rc'      => $rc,
        '_msg'     => $msg,
        '_content' => undef,
        '_header'  => new LWP::MIMEheader,
    }, $class;
}


=head2 code([$code])

=head2 content([$val])

These methods provide public access to the member variables containing
respectively the response code and the content of the response

=cut

sub code      { shift->_elem('_rc',  @_); }
sub message   { shift->_elem('_msg',  @_); }
sub content   { shift->_elem('_content',  @_); }

sub addContent
{
    my($self, $data) = @_;
    $self->{'_content'} .= $$data;
}

=head2 headers()

=head2 header(...)

=head2 pushHeader(...)

These methods provide easy access to the fields for the request header.

=cut

# forward these to the header member variable
sub headers    { shift->{'_header'}; }

sub header     { shift->{'_header'}->header(@_) };
sub pushHeader { shift->{'_header'}->pushHeader(@_) };


=head2 as_string()

Method returning a textual representation of the request.  Mainly
useful for debugging purposes. It takes no arguments.

=cut

sub as_string {
    my $self = shift;
    my $result = "LWP::Response::as_string($self):\n";
    $result .= 'Response Code: ' . $self->_strElem('_rc') . "\n";
    $result .= 'Message: '       . $self->_strElem('_msg') . "\n";
    $result .= $self->headers->as_string;
    $result .= "Content:\n"      . $self->_strElem('_content') . "\n";
    $result .= "\n";
    $result;
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

sub errorAsHTML {
    my $self = shift;
    my $msg = $self->{'_msg'} || 'Unknown';
    my $content = $self->{'_content'} || '';
    if (defined $content and $content) {
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
