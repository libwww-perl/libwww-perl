#
# $Id: Message.pm,v 1.2 1995/07/11 13:21:00 aas Exp $

package LWP::Message;

=head1 NAME

LWP::Message - Class encapsulating HTTP messages

=head1 DESCRIPTION

C<LWP::Message>s consist of requests from client to server and
responses from server to client. This is a pure virtual base 
class for C<LWP::Request> and C<LWP::Response>.

=head1 BUGS

Talk about minimal class :-)

=cut

#####################################################################

require LWP::MemberMixin;
@ISA = qw(LWP::MemberMixin);

#####################################################################

# Copy constructor

sub clone
{
    my $self = shift;
    bless { %$self }, ref $self;
}

1;
