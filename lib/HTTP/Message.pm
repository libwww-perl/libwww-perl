#
# $Id: Message.pm,v 1.8 1995/09/04 20:46:00 aas Exp $

package HTTP::Message;

=head1 NAME

HTTP::Message - Class encapsulating HTTP messages

=head1 DESCRIPTION

A C<HTTP::Message> object contains some headers and a content (body).
The class is used as a pure virtual base class for C<HTTP::Request> and
C<HTTP::Response>.

=head1 METHODS

=cut

#####################################################################

require HTTP::Headers;
require Carp;

=head2 new()

Object constructor.  It should normally only be called internally by
this library.  External code should construct C<HTTP::Request> or
C<HTTP::Response> objects.

=cut

sub new
{
    my($class, $header, $content) = @_;
    if (defined $header) {
        Carp::croak("Bad header argument") unless ref $header;
        $header = $header->clone;
    } else {
        $header = new HTTP::Headers;
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
    my $clone = new HTTP::Message $self->{'_header'}, $self->{'_content'};
    $clone;
}

=head2 content([$content])

=head2 addContent($data)

These methods manages the content of the message.  The C<content()>
method sets the content if an argument is given.  If no argument is
given the content is not touched.  In either case the previous content
is returned.

The addContent() methods appends data to the content.

=cut

sub content   { shift->_elem('_content',  @_); }

sub addContent
{
    my $self = shift;
    if (ref($_[0])) {
	$self->{'_content'} .= ${$_[0]};  # for backwards compatability
    } else {
	$self->{'_content'} .= $_[0];
    }
}


=head2 header($field [, $val]))

=head2 pushHeader($field, $val)

=head2 removeHeader($field)

=head2 headerAsString([$endl])

These methods provide easy access to the fields for the request
header.  Refer to L<HTTP::Headers> for details.

=cut

# forward these to the header member
sub header          { shift->{'_header'}->header(@_);       }
sub pushHeader      { shift->{'_header'}->pushHeader(@_);   }
sub removeHeader    { shift->{'_header'}->removeHeader(@_); }
sub headerAsString  { shift->{'_header'}->asString(@_);     }



# Private method to access members in %$self
sub _elem
{
    my($self, $elem, $val) = @_;
    my $old = $self->{$elem};
    $self->{$elem} = $val if defined $val;
    return $old;
}

1;
