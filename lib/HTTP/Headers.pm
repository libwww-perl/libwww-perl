#
# $Id: Headers.pm,v 1.12 1995/08/27 22:32:25 aas Exp $

package HTTP::Headers;

=head1 NAME

HTTP::Headers - Class encapsulating HTTP Message headers

=head1 SYNOPSIS

 require HTTP::Headers;
 $request = new HTTP::Headers;

=head1 DESCRIPTION

C<HTTP::Headers> is a class encapsulating HTTP style message
headers: attribute value pairs which may be repeated, and are printed
in a particular order.

Instances of this class are usually created as member variables of the
C<HTTP::Request> and C<HTTP::Response> classes, internally to the
library.

=head1 METHODS

=cut


require Carp;


# "Good Practice" order of HTTP message headers:
#    - General-Headers
#    - Request-Headers
#    - Response-Headers
#    - Entity-Headers
# (From draft-ietf-http-v10-spec-01.ps)

my @header_order = qw( 
   Date Forwarded MIME-Version Pragma

   Accept Accept-Charset Accept-Encoding Accept-Language
   Authorization From If-Modified-Since Orig-URI Referer User-Agent

   Location Public Retry-After Server WWW-Authenticate

   Allow Content-Encoding Content-Language Content-Length
   Content-Transfer-Encoding Content-Type
   Expires Last-Modified Link Title URI
);

# Make alternative representations of @header_order.  This is used
# for sorting and case matching.
my $i = 0;
my %header_order;
my %standard_case;  
for (@header_order) {
    my $lc = lc $_;
    $header_order{$lc} = $i++;
    $standard_case{$lc} = $_;
}
undef($i);



=head2 new()

Constructs a new C<HTTP::Headers> object.  You might pass some
initial headers as parameters to the constructor.  E.g.:

 $h = new HTTP::Headers
     'Content-Type' => 'text/html',
     'MIME-Version' => '1.0',
     'Date'         => 'Thu, 03 Feb 1994 00:00:00 GMT';

=cut

sub new
{
    my($class) = shift;
    my $self = bless {
        '_header'   => { },
    }, $class;

    $self->header(@_); # set up initial headers
    $self;
}


=head2 clone()

Returns a copy of the object.

=cut

sub clone
{
    my $self = shift;
    my $clone = new HTTP::Headers;
    $self->scan(sub { $clone->pushHeader(@_);} );
    $clone;
}

=head2 header($field [, $val],...)

Get/Set the value of a request header.  The header field name is not
case sensitive.  The value argument may be a scalar or a reference to
a list of scalars. If the value argument is not defined the header is
not modified.

The method also accepts multiple ($field => $value) pairs.

The list of previous values for the last $field is returned.  Only the
first header value is returned in scalar context.

 $header->header('MIME-Version' => '1.0',
		 'User-Agent'   => 'My-Web-Client/0.01');
 $header->header('Accept' => "text/html, text/plain, image/*");
 @accepts = $header->header('Accept');

=cut

sub header
{
    my $self = shift;
    my($field, $val, @old);
    while (($field, $val) = splice(@_, 0, 2)) {
        @old = $self->_header($field, $val);
    }
    wantarray ? @old : $old[0];
}

sub _header
{
    my($self, $field, $val, $push) = @_;

    # $push is only used interally sub pushHeader

    Carp::croak('Need a field name') unless defined $field;
    Carp::croak('Too many parameters') if @_ > 4;

    my $lc_field = lc $field;
    unless(defined $standard_case{$lc_field}) {
        $field =~ s/\b(\w)/\u$1/g;
        $standard_case{$lc_field} = $field;
    }

    my $thisHeader = \@{$self->{'_header'}{$lc_field}};

    my @old = ();
    if (!$push && defined $thisHeader) {
        @old = @$thisHeader;  # save it so we can return it
    }
    if (defined $val) {
        @$thisHeader = () unless $push;
        if (!ref($val)) {
            # scalar: create list with single value
            push(@$thisHeader, $val);
        } elsif (ref($val) eq 'ARRAY') {
            # list: copy list            
            push(@$thisHeader, @$val);
        } else {
            Carp::croak("Unexpected field value $val");
        }
    }
    @old;
}


=head2 pushHeader($field, $val)

Add a new value to a field of the request header.  The header field
name is not case sensitive.  The field need not already have a
value. Duplicates are retained.  The argument may be a scalar or a
reference to a list of scalars.

 $header->pushHeader('Accept' => 'image/jpeg');

=cut

sub pushHeader
{
    Carp::croak('Usage: $h->pushHeader($field, $val)') if @_ != 3;
    shift->_header(@_, 'PUSH');
}


=head2 removeHeader($field,...)

This function removes the headers with the specified names.

=cut

sub removeHeader
{
    my $self = shift;
    my $field;
    foreach $field (@_) {
        delete $self->{'_header'}{lc $field};
    }
}


# Compare function which makes it easy to sort headers in the
# recommended "Good Practice" order.
sub _headerCmp
{
    # Unknown headers are assign a large value so that they are
    # sorted last.  This also helps avoiding a warning from -w
    # about comparing undefined values.
    $header_order{$a} = 999 unless defined $header_order{$a};
    $header_order{$b} = 999 unless defined $header_order{$b};

    $header_order{$a} <=> $header_order{$b} || $a cmp $b;
}


=head2 scan(\&doit)

Apply the subroutine to each header in turn.  The routine is called
with two parameters; the name of the field and a single value.  If the
header has more than one value, then the routine is called once for
each value.  The C<scan()> routine uses case for the field name as
suggested by HTTP Spec, and follows recommended "Good Practice" of
ordering the header fields.

=cut

sub scan
{
    my($self, $sub) = @_;
    my $field;
    foreach $field (sort _headerCmp keys %{$self->{'_header'}} ) {
        my $list = $self->{'_header'}{$field};
        if (defined $list) {
            my $val;
            for $val (@$list) {
                &$sub($standard_case{$field} || $field, $val);
            }
        }
    }
}


=head2 asString([$endl])

Return the header fields as a formatted MIME header.  Since it uses
C<scan()> to build the string, the result will use case as suggested
by HTTP Spec, and it will follow recommended "Good Practice" of
ordering the header fieds.

=cut

sub asString
{
    my($self, $endl) = @_;
    $endl = "\n" unless defined $endl;

    my @result = ();
    $self->scan(sub {
        my($field, $val) = @_;
	push(@result, "$field: $val");
    });

    join($endl, @result, '');
}

1;
