#
# $Id: Message.pm,v 1.4 1995/07/16 07:22:06 aas Exp $

package LWP::Message;

=head1 NAME

LWP::Message - Class encapsulating HTTP messages

=head1 DESCRIPTION

A C<LWP::Message> object contains some headers and a content (body).
The class is used as a pure virtual base class for C<LWP::Request> and
C<LWP::Response>.

=head1 METHODS

=cut

#####################################################################

require LWP::MemberMixin;
@ISA = qw(LWP::MemberMixin);
require LWP::MIMEheader;
use Carp;

=head2 new()

Object constructor.  It should normally only be called internally by
this library.

=cut

sub new
{
    my($class, $header, $content) = @_;
    if (defined $header) {
        croak "Bad header argument" unless ref($header) eq "LWP::MIMEheader";
        $header = $header->clone;
    } else {
        $header = new LWP::MIMEheader;
    }
    bless {
        '_header'  => $header,
        '_content' => $content,
    }, $class;
}


=head2 clone()

Returns a copy of the object.

=cut

sub clone
{
    my $self  = shift;
    my $clone = new LWP::Message $self->{'_header'}, $self->{'_content'};
    $clone;
}

=head2 content([$content])

=head2 addContent($data_reference)

These methods manages the content of the message.  The C<content()>
method sets the content if an argument is given.  If no argument is
given the content is not touched.  In either case the previous content
is returned.

=cut

sub content   { shift->_elem('_content',  @_); }

sub addContent
{
    my($self, $data) = @_;
    $self->{'_content'} .= $$data;
}


=head2 header($field [, $val]))

=head2 pushHeader($field, $val)

=head2 removeHeader($field)

=head2 headerAsString([$endl])

These methods provide easy access to the fields for the request
header.  Refer to L<LWP::MIMEheader> for details.

=cut

# forward these to the header member variable
sub header          { shift->{'_header'}->header(@_);       }
sub pushHeader      { shift->{'_header'}->pushHeader(@_);   }
sub removeHeader    { shift->{'_header'}->removeHeader(@_); }
sub headerAsString  { shift->{'_header'}->asString(@_);     }

1;
