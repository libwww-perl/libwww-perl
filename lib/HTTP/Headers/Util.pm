package HTTP::Headers::Util;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

require Exporter;
@ISA=qw(Exporter);

@EXPORT_OK=qw(split_header_words join_header_words);

=head1 NAME

HTTP::Headers::Util - Header value parsing utility functions

=head1 SYNPOSIS

  use HTTP::Headers::Util qw(split_header_words);
  @values = split_header_words($h->header("Content-Type"));

=head1 DESCRIPTION

This module provide a few functions that helps parsing and
construction of valid header values.  None of the functions are
exported by default.

The following functions are provided:

=over 4

=item split_header_words( @header_values )

This function will split the header values given as argument into a
list of anonymous arrays containing key/value pairs.  The function
know how to deal with ",", ";" and "=" as well as quoted values.
Multiple values are treated as if they were separated by comma.

This is easier to describe with an example:

   split_header_words('foo="bar"; port="80,81"; discard, bar=baz')
   split_header_words('text/html; charset="iso-8859-1");

will return

   [foo=>'bar', port=>'80,81', discard=> undef], [bar=>'baz' ]
   ['text/html' => undef, charset => 'iso-8859-1']

=cut


sub split_header_words
{
    my(@val) = @_;
    my @res;
    for (@val) {
	my @cur;
	while (length) {
	    if (s/^\s*(=*[^\s=;,]+)//) {
		push(@cur, $1);
		if (s/^\s*=\s*\"([^\"\\]*(?:\\.[^\"\\]*)*)\"//) {
		    my $val = $1;
		    $val =~ s/\\(.)/$1/g;
		    push(@cur, $val);
		} elsif (s/^\s*=\s*([^;,]+)//) {
		    my $val = $1;
		    $val =~ s/\s+$//;
		    push(@cur, $val);
		} else {
		    push(@cur, undef);
		}
	    } elsif (s/^\s*,//) {
		push(@res, [@cur]);
		@cur = ();
	    } elsif (s/^\s*;?//) {
		# continue
	    } else {
		warn "This should not happen: $_\n";
	    }
	}
	push(@res, \@cur) if @cur;
    }
    @res;
}


=item join_header_words( @arrays )

This will do the opposite convertion of what split_header_words()
does.  It takes a list of anonymous arrays as argument and produce a
single header value.  Attribute values are quoted if needed.  Example:

   join_header_words(["text/plain" => undef, charset => "iso-8859/1"]);

=cut

sub join_header_words
{
    my @res;
    for (@_) {
	my @cur = @$_;
	my @attr;
	while (@cur) {
	    my $k = shift @cur;
	    my $v = shift @cur;
	    if (defined $v) {
		if ($v =~ /^\w+$/) {
		    $k .= "=$v";
		} else {
		    $v =~ s/([\"\\])/\\$1/g;  # escape " and \
		    $k .= qq(="$v");
		}
	    }
	    push(@attr, $k);
	}
	push(@res, join("; ", @attr)) if @attr;
    }
    join(", ", @res);
}

1;

__END__

=back

=head1 COPYRIGHT

Copyright 1997, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
