#
# $Id: MemberMixin.pm,v 1.3 1996/02/26 19:12:24 aas Exp $

package LWP::MemberMixin;

=head1 NAME

LWP::MemberMixin - Member access mixin class

=head1 DESCRIPTION

A mixin class to get methods that provide easy access to member
variables in the %$self.

=head1 BUGS

Ideally there should be better Perl langauge support for this.

=head1 METHODS

=head2 _elem($elem [, $val])

Internal method to get/set the value of member variable
C<$elem>. If C<$val> is defined it is used as the new value
for the member variable.  If it is undefined the current
value is not touched. In both cases the previous value of
the member variable is returned.

=cut

sub _elem
{
    my($self, $elem, $val) = @_;
    my $old = $self->{$elem};
    $self->{$elem} = $val if defined $val;
    return $old;
}

1;
