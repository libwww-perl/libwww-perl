#
# $Id: Headers.pm,v 1.4 1995/07/13 14:56:31 aas Exp $

package LWP::MIMEheader;

=head1 NAME

LWP::MIMEheader - Class encapsulating HTTP Message headers

=head1 SYNOPSIS

 require LWP::MIMEheader;
 $request = new LWP::MIMEheader;

=head1 DESCRIPTION

C<LWP::MIMEheader> is a class encapsulating HTTP style message
headers: attribute value pairs which may be repeated, and are printed
in a particular order.

Instances of this class are usually created as member variables of the
C<LWP::Request> and C<LWP::Response> classes, internally to the
library.

=head1 METHODS and FUNCTIONS

=head2 new()

Constructs a new C<LWP::MIMEheader> object.

=cut
sub new {
    my %headers = ();
    bless {
        '_header' => \%headers,
    }, shift;
}

=head2 header($field [, $val])

Get/Set the value of a request header.  Note that case of the header
field name is not touched.  The argument may be undefined (header is
not modified), a scalar or a reference to a list of scalars.

The list of previous values is returned

 $header->header('User-Agent', 'test/.01');
 $header->header('Accept', ['text/html', 'text/plain']);
 @accepts = $header->header('Accept');

=cut

require LWP::Debug;
use Carp;

sub header  {
    my($self, $field, $val) = @_;

    croak('need a field name') unless defined $field;

    LWP::Debug::trace("('$field', " .
               (defined $val ? "'$val'" : 'undef') . ')');

    my @old = ();
    if (exists $self->{'_header'}{$field}) {
        @old = @{ $self->{'_header'}{$field} };
    }
    if (defined $val) {
        if (!ref($val)) {
                # scalar: create list with single value
            @{ $self->{'_header'}{$field} } = ( $val );
        }
        elsif (ref($val) eq 'ARRAY') {
                # list: copy list
            @{ $self->{'_header'}{$field} } = @{ $val };
        }
        else {
            croak("Unexpected field value $val");
        }
    }

    wantarray ? @old : $old[0];
}


=head2 pushHeader($field, $val)

Add a new value to a field of the request header.  Note that case of
the header field name is not touched.  The field need not already have
a value. Duplicates are retained.  The argument may be a scalar or a
reference to a list of scalars.

 $header->pushHeader('Accept', 'image/jpeg');

=cut

sub pushHeader {
    my($self, $field, $val) = @_;

    LWP::Debug::trace("('$field', " .
               (defined $val ? "'$val'" : 'undef') . ')');

    # as per LWP::field()
    if (exists $self->{'_header'}{$field}) {
        if (!ref($val)) {
            push( @{ $self->{'_header'}{$field} }, $val);
        }
        elsif (ref($val) eq 'ARRAY') {
            push( @{ $self->{'_header'}{$field} }, @{ $val });
        }
        else {
            croak("Unexpected field value $val");
        }
    }
    else {
        $self->header($field, $val);
    }
}


=head2 asMIME()

Return the header fields as a formatted MIME header, delimited with
CRLF.

See as_string() for details.

=cut

sub asMIME {
    LWP::Debug::trace('()');

    shift->as_string("\r\n");
}


=head2 as_string()

Return the header fields as a formatted MIME header.  Uses case as
suggested by HTTP Spec, and follows recommended "Good Practice" of
ordering the header fieds.

=cut

sub as_string {
    my($self, $endl, $orderref) = shift;

    LWP::Debug::trace('()');

    $endl = "\n" unless defined $endl;

    # to do efficient case-insensitive association,
    # build up a second hash indexed by lowercase keys
    my %lcs = ();
    for(keys %{ $self->{'_header'} }) {
        @{ $lcs{lc($_)} } = @{ $self->{'_header'}{$_} };
    }

    my $result = '';

    # now process header fields in order
    if (defined $orderref) {
        for(@$orderref) {
            my $lc = lc($_);
            my $list = $lcs{$lc};
            if (defined $list) {
                my $val;
                for $val (@$list) {
                    $result .= "$_: $val$endl";
                }
            }
            delete $lcs{$lc};
        }
    }

    # might have some extension-headers left
    my @left = grep(exists $lcs{lc($_)}, keys %{ $self->{'_header'} });
    for(sort @left) {
        my $list = $self->{'_header'}{$_};
        my $val;
        for $val (@{ $list }) {
            $result .= "$_: $val$endl";
        }
    }

    LWP::Debug::debug("result: $result\n");
    $result;
}

1;
