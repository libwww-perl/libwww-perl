package HTML::Parse;

# $Id: Parse.pm,v 1.22 1996/05/09 10:11:52 aas Exp $

=head1 NAME

parse_html - Parse HTML text

parse_htmlfile - Parse HTML text from file

=head1 SYNOPSIS

 use HTML::Parse;
 $h = parse_htmlfile("test.html");
 print $h->dump;
 $h = parse_html("<p>Some more <i>italic</i> text", $h);
 $h->delete;

 print parse_htmlfile("index.html")->as_HTML;  # tidy up markup in a file

=head1 DESCRIPTION

This module provides functions to parse HTML documents.  The result of
the parsing is a HTML syntax tree with HTML::Element objects as nodes.
Check out L<HTML::Element> for details of methods available to access
the syntax tree.

The parser currently understands HTML 2.0 markup + tables + some
Netscape extentions.

Entites in all text content and attribute values will be expanded by
the parser.

The parser is able to parse HTML text incrementally.  The document can
be given to parse_html() in arbitrary pieces.  The result should be
the same.

The following variables control how parsing takes place:

=over 4

=item $HTML::Parse::IMPLICIT_TAGS

Setting this variable to true will instruct the parser to try to
deduce implicit elements and implicit end tags.  If this variable is
false you get a parse tree that just reflects the text as it stands.
Might be useful for quick & dirty parsing.  Default is true.

Implicit elements have the implicit() attribute set.

=item $HTML::Parse::IGNORE_UNKNOWN

This variable contols whether unknow tags should be represented as
elements in the parse tree.  Default is true.

=item $HTML::Parse::IGNORE_TEXT

Do not represent the text content of elements.  This saves space if
all you want is to examine the structure of the document.  Default is
false.

=item $HTML::Parse::WARN

Call warn() with an apropriate message for syntax errors.  Default is
false.

=back

=head1 BUGS

Does not parse tag attributes with the ">" character in the value
correctly:

   <img src="..." alt="4.4 > V">

If you want to free the memory assosiated with the HTML parse tree,
then you will have to delete it explicitly.  The reason for this is
that perl currently has no proper garbage collector, but depends on
reference counts in the objects.  This scheme fails because the parse
tree contains circular references (parents have references to their
children and children have a reference to their parent).


=head1 SEE ALSO

L<HTML::Element>, L<HTML::Entities>

=head1 COPYRIGHT

Copyright 1995,1996 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@sn.no>

=cut


require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(parse_html parse_htmlfile expand_entities);

require HTML::Element;
require HTML::Entities;

$VERSION = sprintf("%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }


$IMPLICIT_TAGS  = 1;
$IGNORE_UNKNOWN = 1;
$IGNORE_TEXT    = 0;
$WARN           = 0;

sub warning ($)
{
    warn "HTML::Parse: $_[0]\n" if $WARN;
}


# Elements that should only be present in the header
%isHeadElement = map { $_ => 1 } qw(title base link meta isindex nextid);

# Elements that should only be present in the body
%isBodyElement = map { $_ => 1 } qw(h1 h2 h3 h4 h5 h6
				    p pre address blockquote
				    xmp listing
				    a img br hr
				    ol ul dir menu li
				    dl dt dd
				    cite code em kbd samp strong var dfn strike
				    b i u tt small big
				    table tr td th caption
				    form input select option textarea
				   ),
                          # Also known are some Netscape extentions elements
                                 qw(wbr nobr center blink font basefont);

# The following elements must be directly contained in some other
# element than body.

%isPhraseMarkup = map { $_ => 1 } qw(cite code em kbd samp strong var b i u tt
				     a img br hr
				     wbr nobr center blink
				     small big font basefont
				     table
				    );

%isList         = map { $_ => 1 } qw(ul ol dir menu);
%isTableElement = map { $_ => 1 } qw(tr td th caption);
%isFormElement  = map { $_ => 1 } qw(input select option textarea);




sub parse_html ($;$)
{
    my $html = $_[1];
    $html = new HTML::Element 'html' unless $html;
    my $buf = \ $html->{'_buf'};
    $$buf .= $_[0];
    # Handle comments
    if ($html->{_comment}) {
	if ($$buf =~ s/^.*?-->//s) {        # end of comment
	    delete $html->{_comment};
        } elsif ($$buf =~ s/^.*?(--?)$/$1/s) { # might become end of comment
            return $html;            
        } else {
	    $$buf = '';          # still inside comment
	}
    }
    $$buf =~ s/<!--.*?-->//sg;   # remove complete comments
    if ($$buf =~ /<!--.*-$/) {   # perhaps partial "end-of-comment" marker
        return $html;            # delay processing
    }
    if ($$buf =~ s/<!--.*//s) {  # check for start of comment (remove it)
	$html->{_comment} = 1;
    }
    return $html unless length $$buf;

    # Split HTML text into tokens.  We use "<...>" as the tokens we
    # look for and asume that this will separate tags from normal
    # text.  This fails for those documents that contain the ">"
    # character in an attribute value, like this: <foo bar=">">
    my @x = split(/(<[^>]+>)/, $$buf);
    if ($x[-1] =~ m/>/) {                # last token is complete a tag
	$$buf = '';
    } elsif ($x[-1] =~ s/(\s*<.*)//s) {  # last token is partial tag
	$$buf = $1;                      # parse this next time
	pop(@x) unless length $x[-1];
    } elsif ($x[-1] =~ s/(\s+)$//) {     # last token ends with whitespace
        $$buf = $1;
        pop(@x) unless length $x[-1];
    } else {                             # last token is text
	$$buf = '';
    }

    # Process all complete tokens
    for (@x) {
	if (m:^</\s*(\w+)\s*>$:) {
	    endtag($html, lc $1);
	} elsif (m/^<\s*\w+/) {
	    starttag($html, $_);
	} elsif (m/^<!\s*DOCTYPE\b/i) {
	    # just ignore it
	} else {
	    text($html, $_);
	}
    }
    $html;
}


sub parse_htmlfile ($)
{
    my $file = shift;
    open(F, $file) or return new HTML::Element 'html', 'comment' => $!;
    my $html = undef;
    my $chunk = '';
    while(read(F, $chunk, 1024)) {
	$html = parse_html($chunk, $html);
    }
    close(F);
    $html;
}



sub starttag
{
    my $html = shift;
    my $elem = shift;

    $elem =~ s/^<\s*(\w+)\s*//;
    my $tag = $1;
    $elem =~ s/>$//;
    unless (defined $tag) {
	warning "Illegal start tag $_[0]";
    } else {
	$tag = lc $tag;
	#print "START: $tag\n";
	my %attr;
	while ($elem =~ s/^([^\s=]+)\s*(=\s*)?//) {
	    $key = $1;
	    if (defined $2) {
		# read value
		if ($elem =~ s/^"([^\"]*)"?\s*//) {       # doble quoted val
		    $val = $1;
		} elsif ($elem =~ s/^'([^\']*)'?\s*//) {  # single quoted val
		    $val = $1;
		} elsif ($elem =~ s/^(\S*)\s*//) {        # unquoted val
		    $val = $1;
		} else {
		    die "This should not happen";
		}
		# expand entities
		HTML::Entities::decode($val);
	    } else {
		# boolean attribute
		$val = $key;
	    }
	    $attr{$key} = $val;
	}

	my $pos  = $html->{_pos};
	$pos = $html unless defined $pos;
	my $ptag = $pos->{_tag};
	my $e = new HTML::Element $tag, %attr;

	if (!$IMPLICIT_TAGS) {
	    # do nothing
	} elsif ($isBodyElement{$tag}) {

	    # Ensure that we are within <body>
	    if ($pos->is_inside('head')) {
		endtag($html, 'head');
		$pos = $html->insert_element('body', 1);
		$ptag = $pos->tag;
	    } elsif (!$pos->is_inside('body')) {
		$pos = $html->insert_element('body', 1);
		$ptag = $pos->tag;
	    }

	    # Handle implicit endings and insert based on <tag> and position
	    if ($tag eq 'p' || $tag =~ /^h[1-6]/ || $tag eq 'form') {
		# Can't have <p>, <h#> or <form> inside these
		endtag($html, [qw(p h1 h2 h3 h4 h5 h6 pre textarea)], 'li');
	    } elsif ($tag =~ /^[oud]l$/) {
		# Can't have lists inside <h#>
		if ($ptag =~ /^h[1-6]/) {
		    endtag($html, $ptag);
		    $pos = $html->insert_element('p', 1);
		    $ptag = 'p';
		}
	    } elsif ($tag eq 'li') {
		# Fix <li> outside list
		endtag($html, 'li', keys %isList);
		$ptag = $html->pos->tag;
		$pos = $html->insert_element('ul', 1) unless $isList{$ptag};
	    } elsif ($tag eq 'dt' || $tag eq 'dd') {
		endtag($html, ['dt', 'dd'], 'dl');
		$ptag = $html->pos->tag;
		# Fix <dt> or <dd> outside <dl>
		$pos = $html->insert_element('dl', 1) unless $ptag eq 'dl';
	    } elsif ($isFormElement{$tag}) {
		return unless $pos->is_inside('form');
		if ($tag eq 'option') {
		    # return unless $ptag eq 'select';
		    endtag($html, 'option');
		    $ptag = $html->pos->tag;
		    $pos = $html->insert_element('select', 1)
		      unless $ptag eq 'select';
		}
	    } elsif ($isTableElement{$tag}) {
		endtag($html, $tag, 'table');
		$pos = $html->insert_element('table', 1)
		  if !$pos->is_inside('table');
	    } elsif ($isPhraseMarkup{$tag}) {
		if ($ptag eq 'body') {
		    $pos = $html->insert_element('p', 1);
		}
	    }
	} elsif ($isHeadElement{$tag}) {
	    if ($pos->is_inside('body')) {
		warning "Header element <$tag> in body";
	    } elsif (!$pos->is_inside('head')) {
		$pos = $html->insert_element('head', 1);
	    }
	} elsif ($tag eq 'html') {
	    if ($ptag eq 'html' && $pos->is_empty()) {
		# migrate attributes to origial HTML element
		for (keys %attr) {
		    $html->attr($_, $attr{$_});
		}
		return;
	    } else {
		warning "Skipping nested <html> element";
		return;
	    }
	} elsif ($tag eq 'head') {
	    if ($ptag ne 'html' && $pos->is_empty()) {
		warning "Skipping nested <head> element";
		return;
	    }
	} elsif ($tag eq 'body') {
	    if ($pos->is_inside('head')) {
		endtag($html, 'head');
	    } elsif ($ptag ne 'html') {
		warning "Skipping nested <body> element";
		return;
	    }
	} else {
	    # unknown tag
	    if ($IGNORE_UNKNOWN) {
		warning "Skipping unknown tag $tag";
		return;
	    }
	}
	$html->insert_element($e);
    }
}


sub endtag
{
    my($html, $tag, @stop) = @_;

    # End the specified tag, but don't move above any of the @stop tags.
    # The tag can also be a reference to an array.  Terminate the first
    # tag found.

    my $p = $html->{_pos};
    $p = $html unless defined($p);
    if (ref $tag) {
      PARENT:
	while (defined $p) {
	    my $ptag = $p->{_tag};
	    for (@$tag) {
		last PARENT if $ptag eq $_;
	    }
	    for (@stop) {
		return if $ptag eq $_;
	    }
	    $p = $p->{_parent};
	}
    } else {
	while (defined $p) {
	    my $ptag = $p->{_tag};
	    last if $ptag eq $tag;
	    for (@stop) {
		return if $ptag eq $_;
	    }
	    $p = $p->{_parent};
	}
    }

    # Move position if the specified tag was found
    $html->{_pos} = $p->{_parent} if defined $p;
}


sub text ($$)
{
    my $html = shift;
    my $pos = $html->{_pos};
    $pos = $html unless defined($pos);

    my $text = shift;
    return unless length $text;

    HTML::Entities::decode($text) unless $IGNORE_TEXT;

    if ($pos->is_inside(qw(pre xmp listing))) {
	return if $IGNORE_TEXT;
	$pos->push_content(@text);
    } else {
	# return unless $text =~ /\S/;  # This is sometimes wrong

	my $ptag = $pos->{_tag};
	if (!$IMPLICIT_TAGS || $text !~ /\S/) {
	    # don't change anything
	} elsif ($ptag eq 'head') {
	    endtag($html, 'head');
	    $html->insert_element('body', 1);
	    $pos = $html->insert_element('p', 1);
	} elsif ($ptag eq 'html') {
	    $html->insert_element('body', 1);
	    $pos = $html->insert_element('p', 1);
	} elsif ($ptag eq 'body' ||
	       # $ptag eq 'li'   ||
	       # $ptag eq 'dd'   ||
		 $ptag eq 'form') {
	    $pos = $html->insert_element('p', 1);
	}
	return if $IGNORE_TEXT;
	$text =~ s/\s+/ /g;  # canoncial space
	$pos->push_content($text);
    }
}

1;
