# $Id: Common.pm,v 1.3 1997/08/04 15:38:58 aas Exp $
#
package HTTP::Request::Common;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

require Exporter;
@ISA=qw(Exporter);

@EXPORT=qw(GET HEAD PUT POST);
@EXPORT_OK=qw(cat);

require HTTP::Request;
use Carp();

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

my $CRLF = "\015\012";   # "\r\n" is not portable

sub GET  { _simple_req('GET',  @_); }
sub HEAD { _simple_req('HEAD', @_); }
sub PUT  { _simple_req('PUT' , @_); }

sub POST
{
    my $url = shift;
    my $req = HTTP::Request->new(POST => $url);
    my $content;
    $content = shift if @_ and ref $_[0];
    my($k, $v);
    while (($k,$v) = splice(@_, 0, 2)) {
	if (lc($k) eq 'content') {
	    $content = $v;
	} else {
	    $req->push_header($k, $v);
	}
    }
    my $ct = $req->header('Content-Type');
    unless ($ct) {
	$ct = 'application/x-www-form-urlencoded';
    } elsif ($ct eq 'form-data') {
	$ct = 'multipart/form-data';
    }

    if (ref $content) {
	if (lc($ct) eq 'multipart/form-data') {    #XXX: boundary="..."
	    my $boundary;
	    ($content, $boundary) = form_data($content, $boundary);
	    $ct = qq(multipart/form-data; boundary="$boundary");
	} else {
	    # We use a temporary URI::URL object to format
	    # the application/x-www-form-urlencoded content.
	    require URI::URL;
	    my $url = URI::URL->new('http:');
	    $url->query_form(@$content);
	    $content = $url->equery;
	}
    }

    $req->header('Content-Type' => $ct);  # might be redundant
    if (defined($content)) {
	$req->header('Content-Length' => length($content));
	$req->content($content);
    }
    $req;
}


sub _simple_req
{
    my($method, $url) = splice(@_, 0, 2);
    my $req = HTTP::Request->new($method => $url);
    my($k, $v);
    while (($k,$v) = splice(@_, 0, 2)) {
	if (lc($k) eq 'content') {
	    $req->add_content($v);
	} else {
	    $req->push_header($k, $v);
	}
    }
    $req;
}


sub form_data   # RFC1867
{
    my($data, $boundary) = @_;
    my @parts;
    my($k,$v);
    while (($k,$v) = splice(@$data, 0, 2)) {
	if (ref $v) {
	    my $file = shift(@$v);
	    my $usename = shift(@$v);
	    unless (defined $usename) {
		$usename = $file;
		$usename =~ s,.*/,, if defined($usename);
	    }
	    my $disp = qq(form-data; name="$k");
	    $disp .= qq(; filename="$usename") if $usename;
	    my $content = "";
	    my $h = HTTP::Headers->new(@$v);
	    my $ct = $h->header("Content-Type");
	    if ($file) {
		local(*F);
		local($/) = undef; # slurp files
		open(F, $file) or Carp::croak("Can't open file $file: $!");
		$content = <F>;
		close(F);
		unless ($ct) {
		    require LWP::MediaTypes;
		    $ct = LWP::MediaTypes::guess_media_type($file);
		    $h->header("Content-Type" => $ct); # XXX: content-encoding
		}
	    }
	    if ($h->header("Content-Disposition")) {
		$h->remove_header("Content-Disposition");
		$disp = $h->remove_header("Content-Disposition");
	    }
	    if ($h->header("Content")) {
		$content = $h->header("Content");
		$h->remove_header("Content");
	    }
	    push(@parts, "Content-Disposition: $disp$CRLF" .
                         $h->as_string($CRLF) .
                         "$CRLF$content");
	} else {
	    push(@parts, qq(Content-Disposition: form-data; name="$k"$CRLF$CRLF$v));
	}
    }
    return "" unless @parts;
    $boundary = boundary() unless $boundary;

    my $bno = 1;
  CHECK_BOUNDARY:
    {
	for (@parts) {
	    if (index($_, $boundary) >= 0) {
		# must have a better boundary
		#warn "Need something better that '$boundary' as boundary\n";
		$boundary = boundary(++$bno);
		redo CHECK_BOUNDARY;
	    }
	}
	last;
    }

    my $content = "--$boundary$CRLF" .
                  join("$CRLF--$boundary$CRLF", @parts) .
                  "$CRLF--$boundary--$CRLF";
    wantarray ? ($content, $boundary) : $content;
}


sub boundary
{
    my $size = shift || 1;
    require MIME::Base64;
    MIME::Base64::encode(join("", map chr(rand(256)), 1..$size*3), "");
}

1;

__END__

=head1 NAME

HTTP::Request::Common - Construct common HTTP::Request objects

=head1 SYNOPSIS

  use HTTP::Request::Common;
  $ua = LWP::UserAgent->new;
  $ua->request(GET 'http://www.sn.no/');
  $ua->request(POST 'http://somewhere/foo', [foo => bar, bar => foo]);

=head1 DESCRIPTION

This module provide functions that return newly created HTTP::Request
objects.  These functions are usually more convenient than the
standard HTTP::Request constructor for these common requests.  The
following functions are provided.

=over 4

=item GET $url, [Header => Value,...]

The GET() function returns a HTTP::Request object initialized with the
GET method and the specified URL.  Without additional arguments it
is exactly equivalent to the following call

  HTTP::Request->new(GET => $url)

but is less clutter.  It also reads better when used together with the
LWP::UserAgent->request() method:

  my $ua = new LWP::UserAgent;
  my $res = $ua->request(GET 'http://www.sn.no')
  if ($res->is_success) { ...

You can also initialize the header values in the request by specifying
some key/value pairs as optional arguments.  For instance:

  $ua->request(GET 'http://www.sn.no',
	           If_Match => 'foo',
                   From     => 'gisle@aas.no',
              );

A header key called 'Content' is special and when seen the value will
initialize the content part of the request instead of setting a header.

=item HEAD $url, [Header => Value,...]

Like GET() but the method in the request is HEAD.

=item PUT $url, [Header => Value,...]

Like GET() but the method in the request is PUT.

=item POST $url, [$form_ref], [Header => Value,...]

This works mostly like GET() with POST as method, but this function
also takes a second optional array reference parameter ($form_ref).
This argument can be used to pass key/value pairs for the form
content.  By default we will initialize a request using the
C<application/x-www-form-urlencoded> content type.  This means that
you can emulate a HTML E<lt>form> POSTing like this:

  POST 'http://www.perl.org/survey.cgi',
       [ name  => 'Gisle',
         email => 'gisle@aas.no',
         gender => 'm',
         born   => '1964',
         trust  => '3%',
	];

This will create a HTTP::Request object that looks like this:

  POST http://www.perl.org/survey.cgi
  Content-Length: 61
  Content-Type: application/x-www-form-urlencoded

  name=Gisle&email=gisle%40aas.no&gender=m&born=1964&trust=3%25

The POST method also supports the C<multipart/form-data> content used
for I<Form-based File Upload> as specified in RFC 1867.  You trigger
this content format by specifying a content type of C<'form-data'>.
If one of the values in the $form_ref is an array reference, then it
is treated as a file part specification with the following values:

  [ $file, $filename, Header => Value... ]

The first value in the array ($file) is the name of a file to open.
This file will be read an its content placed in the request.  The
routine will croak if the file can't be opened.  Use an undef as $file
value if you want to specify the content directly.  The $filename is
the filename to report in the request.  If this value is undefined,
then the basename of the $file will be used.  You can specify an empty
string as $filename if you don't want any filename in the request.

Sending my F<~/.profile> to the survey used as example above can be
achieved by this:

  POST 'http://www.perl.org/survey.cgi',
       Content_Type => 'form-data',
       Content      => [ name  => 'Gisle Aas',
                         email => 'gisle@aas.no',
                         gender => 'm',
                         born   => '1964',
                         init   => ["$ENV{HOME}/.profile"],
                       ]

This will create a HTTP::Request object that almost looks this (the
boundary and the content of your F<~/.profile> is likely to be
different):

  POST http://www.perl.org/survey.cgi
  Content-Length: 388
  Content-Type: multipart/form-data; boundary="6G+f"

  --6G+f
  Content-Disposition: form-data; name="name"
  
  Gisle Aas
  --6G+f
  Content-Disposition: form-data; name="email"
  
  gisle@aas.no
  --6G+f
  Content-Disposition: form-data; name="gender"
  
  m
  --6G+f
  Content-Disposition: form-data; name="born"
  
  1964
  --6G+f
  Content-Disposition: form-data; name="init"; filename=".profile"
  Content-Type: text/plain
  
  PATH=/local/perl/bin:$PATH
  export PATH

  --6G+f--

=back

=head1 SEE ALSO

L<HTTP::Request>, L<LWP::UserAgent>


=head1 COPYRIGHT

Copyright 1997, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

