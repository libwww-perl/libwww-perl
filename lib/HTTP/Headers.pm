#
# $Id: Headers.pm,v 1.26 1996/09/16 12:49:47 aas Exp $

package HTTP::Headers;

=head1 NAME

HTTP::Headers - Class encapsulating HTTP Message headers

=head1 SYNOPSIS

 require HTTP::Headers;
 $request = new HTTP::Headers;

=head1 DESCRIPTION

The C<HTTP::Headers> class encapsulates HTTP-style message headers.
The headers consist of attribute-value pairs, which may be repeated,
and which are printed in a particular order.

Instances of this class are usually created as member variables of the
C<HTTP::Request> and C<HTTP::Response> classes, internal to the
library.

=head1 METHODS

=cut


require Carp;

# Could not use the AutoLoader becase several of the method names are
# not unique in the first 8 characters.
#use SelfLoader;


# "Good Practice" order of HTTP message headers:
#    - General-Headers
#    - Request-Headers
#    - Response-Headers
#    - Entity-Headers
#    - Aditional Headers (§19.6.2)
# (From draft-ietf-http-v11-spec-06, Jul 4, 1996)

my @header_order = qw(
   Cache-Control Connection Date Pragma Transfer-Encoding Upgrade Via

   Accept Accept-Charset Accept-Encoding Accept-Language
   Authorization From Host
   If-Modified-Since If-Match If-None-Match If-Range If-Unmodified-Since
   Max-Forwards Proxy-Authorization Range Referer User-Agent

   Age Location Proxy-Authenticate Public Retry-After Server Vary
   Warning WWW-Authenticate

   Allow Content-Base Content-Encoding Content-Language Content-Length
   Content-Location Content-MD5 Content-Range Content-Type
   ETag Expires Last-Modified

   Alternates Content-Version Derived-From Link URI
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



=head2 $h = new HTTP::Headers

Constructs a new C<HTTP::Headers> object.  You might pass some initial
attribute-value pairs as parameters to the constructor.  I<E.g.>:

 $h = new HTTP::Headers
     Date         => 'Thu, 03 Feb 1994 00:00:00 GMT',
     Content_Type => 'text/html; version=3.2',
     Content_Base => 'http://www.sn.no/';

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


=head2 $h->header($field [=> $val],...)

Get or set the value of a header.  The header field name is not case
sensitive.  To make the life easier for perl users who wants to avoid
quoting before the => operator, you can use '_' as a synonym for '-'
in header names.

The value argument may be a scalar or a reference to a list of
scalars. If the value argument is not defined, then the header is not
modified.

The header() method accepts multiple ($field => $value) pairs.

The list of previous values for the last $field is returned.  Only the
first header value is returned in scalar context.

 $header->header(MIME_Version => '1.0',
		 User_Agent   => 'My-Web-Client/0.01');
 $header->header(Accept => "text/html, text/plain, image/*");
 $header->header(Accept => [qw(text/html text/plain image/*)]);
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
    $field =~ tr/_/-/;  # allow use of '_' as alternative to '-' in fields

    # $push is only used interally sub push_header

    Carp::croak('Need a field name') unless defined $field;
    Carp::croak('Too many parameters') if @_ > 4;

    my $lc_field = lc $field;
    unless(defined $standard_case{$lc_field}) {
	# generate a %stadard_case entry for this field
	$field =~ s/\b(\w)/\u$1/g;
	$standard_case{$lc_field} = $field;
    }

    my $this_header = \@{$self->{'_header'}{$lc_field}};

    my @old = ();
    if (!$push && defined $this_header) {
	@old = @$this_header;  # save it so we can return it
    }
    if (defined $val) {
	@$this_header = () unless $push;
	if (!ref($val)) {
	    # scalar: create list with single value
	    push(@$this_header, $val);
	} elsif (ref($val) eq 'ARRAY') {
	    # list: copy list
	    push(@$this_header, @$val);
	} else {
	    Carp::croak("Unexpected field value $val");
	}
    }
    @old;
}


# Compare function which makes it easy to sort headers in the
# recommended "Good Practice" order.
sub _header_cmp
{
    # Unknown headers are assign a large value so that they are
    # sorted last.  This also helps avoiding a warning from -w
    # about comparing undefined values.
    $header_order{$a} = 999 unless defined $header_order{$a};
    $header_order{$b} = 999 unless defined $header_order{$b};

    $header_order{$a} <=> $header_order{$b} || $a cmp $b;
}


=head2 $h->scan(\&doit)

Apply a subroutine to each header in turn.  The callback routine is
called with two parameters; the name of the field and a single value.
If the header has more than one value, then the routine is called once
for each value.  The field name passed to the callback routine has
case as suggested by HTTP Spec, and the headers will be visited in the
recommended "Good Practice" order.

=cut

sub scan
{
    my($self, $sub) = @_;
    my $field;
    foreach $field (sort _header_cmp keys %{$self->{'_header'}} ) {
	my $list = $self->{'_header'}{$field};
	if (defined $list) {
	    my $val;
	    for $val (@$list) {
		&$sub($standard_case{$field} || $field, $val);
	    }
	}
    }
}


=head2 $h->as_string([$endl])

Return the header fields as a formatted MIME header.  Since it
internally uses the C<scan()> method to build the string, the result
will use case as suggested by HTTP Spec, and it will follow
recommended "Good Practice" of ordering the header fieds.  Long header
values are not folded. 

The optional parameter specifies the line ending sequence to use.  The
default is C<"\n">.  Embedded "\n" characters in the header will be
substitued with this line ending sequence.

=cut

sub as_string
{
    my($self, $endl) = @_;
    $endl = "\n" unless defined $endl;

    my @result = ();
    $self->scan(sub {
	my($field, $val) = @_;
	if ($val =~ /\n/) {
	    # must handle header values with embedded newlines with care
	    $val =~ s/\s+$//;          # trailing newlines and space must go
	    $val =~ s/\n\n+/\n/g;      # no empty lines
	    $val =~ s/\n([^\040\t])/\n $1/g;  # intial space for continuation
	    $val =~ s/\n/$endl/g;      # substitute with requested line ending
	}
	push(@result, "$field: $val");
    });

    join($endl, @result, '');
}


# The remaining functions should autoloaded only when needed

# A bug in 5.002gamma makes it risky to have POD text inside the
# autoloaded section of the code, so we keep the documentation before
# the __DATA__ token.

=head2 $h->push_header($field, $val)

Add a new field value of the specified header.  The header field name
is not case sensitive.  The field need not already have a
value. Previous values for the same field are retained.  The argument
may be a scalar or a reference to a list of scalars.

 $header->push_header(Accept => 'image/jpeg');

=head2 $h->remove_header($field,...)

This function removes the headers with the specified names.

=head2 $h->clone

Returns a copy of this HTTP::Headers object.

=head1 CONVENIENCE METHODS

The most frequently used headers can also be accessed through the
following convenience methods.  These methods can both be used to read
and to set the value of a header.  The header value is set if you pass
an argument to the method.  The old header value is always returned.

Methods that deal with dates/times always convert their value to system
time (seconds since Jan 1, 1970) and they also expect this kind of
value when the header value is set.

=head2 $h->date

This header represents the date and time at which the message was
originated. I<E.g.>:

  $h->date(time);  # set current date

=head2 $h->expires

This header gives the date and time after which the entity should be
considered stale.

=head2 $h->if_modified_since

This header is used to make a request conditional.  If the requested
resource has not been modified since the time specified in this field,
then the server will return a C<"304 Not Modified"> response instead of
the document itself.

=head2 $h->last_modified

This header indicates the date and time at which the resource was last
modified. I<E.g.>:

  # check if document is more than 1 hour old
  if ($h->last_modified < time - 60*60) {
	...
  }

=head2 $h->content_type

The Content-Type header field indicates the media type of the message
content. I<E.g.>:

  $h->content_type('text/html');

The value returned will be converted to lower case, and potential
parameters will be chopped off and returned as a separate value if in
an array context.  This makes it safe to do the following:

  if ($h->content_type eq 'text/html') {
     # we enter this place even if the real header value happens to
     # be 'TEXT/HTML; version=3.0'
     ...
  }

=head2 $h->content_encoding

The Content-Encoding header field is used as a modifier to the
media type.  When present, its value indicates what additional
encoding mechanism has been applied to the resource.

=head2 $h->content_length

A decimal number indicating the size in bytes of the message content.

=head2 $h->title

The title of the document.  In libwww-perl this header will be
initialized automatically from the E<lt>TITLE>...E<lt>/TITLE> element
of HTML documents.  I<This header is no longer part of the HTTP
standard.>

=head2 $h->user_agent

This header field is used in request messages and contains information
about the user agent originating the request.  I<E.g.>:

  $h->user_agent('Mozilla/1.2');

=head2 $h->server

The server header field contains information about the software being
used by the originating server program handling the request.

=head2 $h->from

This header should contain an Internet e-mail address for the human
user who controls the requesting user agent.  The address should be
machine-usable, as defined by RFC822.  E.g.:

  $h->from('Gisle Aas <aas@sn.no>');

=head2 $h->referer

Used to specify the address (URI) of the document from which the
requested resouce address was obtained.

=head2 $h->www_authenticate

This header must be included as part of a "401 Unauthorized" response.
The field value consist of a challenge that indicates the
authentication scheme and parameters applicable to the requested URI.

=head2 $h->authorization

A user agent that wishes to authenticate itself with a server, may do
so by including this header.

=head2 $h->authorization_basic

This method is used to get or set an authorization header that use the
"Basic Authentication Scheme".  In array context it will return two
values; the user name and the password.  In scalar context it will
return I<"uname:password"> as a single string value.

When used to set the header value, it expects two arguments.  I<E.g.>:

  $h->authorization_basic($uname, $password);

=cut

1;

#__DATA__

sub clone
{
    my $self = shift;
    my $clone = new HTTP::Headers;
    $self->scan(sub { $clone->push_header(@_);} );
    $clone;
}

sub push_header
{
    Carp::croak('Usage: $h->push_header($field, $val)') if @_ != 3;
    shift->_header(@_, 'PUSH');
}


sub remove_header
{
    my($self, @fields) = @_;
    my $field;
    foreach $field (@fields) {
	$field =~ tr/_/-/;
	delete $self->{'_header'}{lc $field};
    }
}

# Convenience access functions

sub _date_header
{
    require HTTP::Date;
    my($self, $header, $time) = @_;
    my($old) = $self->_header($header);
    if (defined $time) {
	$self->_header($header, HTTP::Date::time2str($time));
    }
    HTTP::Date::str2time($old);
}

sub date              { shift->_date_header('Date',              @_); }
sub expires           { shift->_date_header('Expires',           @_); }
sub if_modified_since { shift->_date_header('If-Modified-Since', @_); }
sub last_modified     { shift->_date_header('Last-Modified',     @_); }

# This is used as a private LWP extention.  The Client-Date header is
# added as a timestamp to a response when it has been received.
sub client_date       { shift->_date_header('Client-Date',       @_); }

# The retry_after field is dual format (can also be a expressed as
# number of seconds from now), so we don't provide an easy way to
# access it until we have know how both these interfaces can be
# addressed.
#sub retry_after       { shift->_date_header('Retry-After',       @_); }

sub content_type      {
  my $ct = (shift->_header('Content-Type', @_))[0];
  return '' unless defined $ct;
  my @ct = split(/\s*;\s*/, lc($ct));
  wantarray ? @ct : $ct[0];
}

sub title             { (shift->_header('Title',            @_))[0] }
sub content_encoding  { (shift->_header('Content-Encoding', @_))[0] }
sub content_length    { (shift->_header('Content-Length',   @_))[0] }

sub user_agent        { (shift->_header('User-Agent',       @_))[0] }
sub server            { (shift->_header('Server',           @_))[0] }

sub from              { (shift->_header('From',             @_))[0] }
sub referer           { (shift->_header('Referer',          @_))[0] }

sub www_authenticate  { (shift->_header('WWW-Authenticate', @_))[0] }
sub authorization     { (shift->_header('Authorization',    @_))[0] }

sub authorization_basic {
    require MIME::Base64;
    my($self, $user, $passwd) = @_;
    my($old) = $self->_header('Authorization');
    if (defined $user) {
	$passwd = '' unless defined $passwd;
	$self->_header('Authorization',
		       'Basic ' . MIME::Base64::encode("$user:$passwd", ''));
    }
    if (defined $old && $old =~ s/^\s*Basic\s+//) {
	my $val = MIME::Base64::decode($old);
	return $val unless wantarray;
	return split(/:/, $val, 2);
    }
    undef;
}

1;
