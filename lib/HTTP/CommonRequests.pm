# $Id: CommonRequests.pm,v 1.1 1997/05/20 20:16:57 aas Exp $
#
package HTTP::CommonRequests;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

require Exporter;
@ISA=qw(Exporter);

@EXPORT=qw(GET HEAD PUT POST);
@EXPORT_OK=qw(cat);

require HTTP::Request;
use Carp();

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

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
		$usename =~ s,.*/,,;
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
		    $h->header("Content-Type" => $ct);
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
	    push(@parts, "Content-Disposition: $disp\n" .
                         $h->as_string .
                         "\n$content");
	} else {
	    push(@parts, qq(Content-Disposition: form-data; name="$k"\n\n$v));
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

    my $content = "--$boundary\n" .
                  join("\n--$boundary\n", @parts) .
                  "\n--$boundary--\n";
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

HTTP::CommonRequests - Construct common HTTP::Request objects

=head1 SYNOPSIS

  use HTTP::CommonRequests;
  $ua->request(GET 'http://www.sn.no/');
  $ua->request(POST 'http://somewhere/foo', [foo => bar, bar => foo]);

=head1 DESCRIPTION

This module provide functions that return newly created HTTP::Request
objects.

=head1 SEE ALSO

L<HTTP::Request>, L<LWP::UserAgent>


=head1 COPYRIGHT

Copyright 1997, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

