package HTML::Parse;

# $Id: Parse.pm,v 1.11 1995/09/13 07:40:10 aas Exp $

=head1 NAME

parse_html - Parse HTML text

parse_htmlfile - Parse HTML text from file

=head1 SYNOPSIS

 use HTML::Parse;
 $h = parse_htmlfile("test.html");
 print $h->dump;
 $h = parse_html("<p>Some more <i>italic</i> text", $h);
 $h->delete;

 print parse_htmlfile("index.html")->asHTML;  # tidy up markup in a file

=head1 DESCRIPTION

This module provides functions to parse HTML text.  The result of the
parsing is a HTML syntax tree with HTML::Element objects as nodes.
Check out L<HTML::Element> for details of methods available to access
the syntax tree.

The parser currently understands HTML 2.0 markup + tables + some
Netscape extentions.

Entites in all text content and attribute values will be expanded by
the parser.

You must delete the parse tree explicitly to free the memory
assosiated with it before the perl interpreter terminates.  The reason
for this is that the parse tree contains circular references (parents
have references to their children and children have a reference to
their parent).

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

=back

=head1 SEE ALSO

L<HTML::Element>, L<HTML::Entities>

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut


require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(parse_html parse_htmlfile expand_entities);

require HTML::Element;
require HTML::Entities;

$VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }


$IMPLICIT_TAGS  = 1;
$IGNORE_UNKNOWN = 1;
$IGNORE_TEXT    = 0;


# Elements that should only be present in the header
for (qw(title base link meta isindex nextid)) {
    $isHeadElement{$_} = 1;
}


# Elements that should only be present in the body
for (qw(h1 h2 h3 h4 h5 h6
	p pre address blockquote
	xmp listing
	a img br hr
	ol ul dir menu li
	dl dt dd
	cite code em kbd samp strong var dfn strike
	b i u tt
	table tr td th caption
	form input select option textarea
       )
    ) {
    $isBodyElement{$_} = 1;
}

# Also known are some Netscape extentions elements
for (qw(wbr nobr center blink font basefont)) {
    $isBodyElement{$_} = 1;
}


# The following elements must be directly contained in some other
# element than body.

for (qw(cite code em kbd samp strong var b i u tt
	a img br hr
	wbr nobr center blink font basefont
	table
       )
    ) {
    $isPhraseMarkup{$_} = 1;
}


# Lists
for (qw(ul ol dir menu)) {
    $isList{$_} = 1;
}


# Table elements
for (qw(tr td th caption)) {
    $isTableElement{$_} = 1;
}


# Form elements
for (qw(input select option textarea)) {
    $isFormElement{$_} = 1;
}




sub parse_html
{
    my $html = $_[1];
    $html = new HTML::Element 'html' unless defined $html;
    my $buf = \ $html->{'_buf'};
    $$buf .= $_[0];
    # Handle comments
    if ($html->{_comment}) {
	if ($$buf =~ s/^.*?-->//s) {        # end of comment
	    delete $html->{_comment};
	} else {
	    $$buf = '';          # still inside comment
	}
    }
    $$buf =~ s/<!--.*?-->//sg;   # remove complete comments
    if ($$buf =~ s/<!--.*//s) {  # check for start of comment
	$html->{_comment} = 1;
    }
    return $html unless length $$buf;
    
    # Split HTML text into tokens.
    my @x = split(/(<[^>]+>)/, $$buf);
    if ($x[-1] =~ m/>/) {              # last token is complete a tag
	$$buf = '';
    } elsif ($x[-1] =~ s/(<.*)//s) {   # last token is partial tag
	$$buf = $1;                    # parse this next time
	pop(@x) unless length $x[-1];
    } else {                           # last token is text
	$$buf = '';
    }

    # Process all complete tokens
    for (@x) {
	if (m:^</\s*(\w+)\s*>$:) {
	    endtag($html, lc $1);
	} elsif (m/^<\s*\w+/) {
	    starttag($html, $_);
	} elsif (m/^<!\s*DOCTYPE\b/) {
	    # just ignore it
	} else {
	    text($html, $_);
	}
    }
    $html;
}


sub parse_htmlfile
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
	warn "Illegal start tag $_[0]";
    } else {
	$tag = lc $tag;
	#print "START: $tag\n";
	my %attr;
	while ($elem =~ s/^([^\s=]+)\s*(=\s*)?//) {
	    $key = $1;
	    if (defined $2) {
		# read value
		if ($elem =~ s/^"([^\"]+)"?\s*//) {       # doble quoted val
		    $val = $1;
		} elsif ($elem =~ s/^'([^\']+)'?\s*//) {  # single quoted val
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
	    if ($pos->isInside('head')) {
		endtag($html, 'head');
		$pos = $html->insertElement('body', 1);
		$ptag = $pos->tag;
	    } elsif (!$pos->isInside('body')) {
		$pos = $html->insertElement('body', 1);
		$ptag = $pos->tag;
	    }

	    # Handle implicit endings and insert based on <tag> and position
	    if ($tag eq 'p' || $tag =~ /^h[1-6]/) {
		# Can't have <p> or <h#> inside these
		endtag($html, [qw(p h1 h2 h3 h4 h5 h6 pre textarea)], 'li');
	    } elsif ($tag =~ /^[oud]l$/) {
		# Can't have lists inside <h#>
		if ($ptag =~ /^h[1-6]/) {
		    endtag($html, $ptag);
		    $pos = $html->insertElement('p', 1);
		    $ptag = 'p';
		}
	    } elsif ($tag eq 'li') {
		# Fix <li> outside list
		endtag($html, 'li', keys %isList);
		$ptag = $html->pos->tag;
		$pos = $html->insertElement('ul', 1) unless $isList{$ptag};
	    } elsif ($tag eq 'dt' || $tag eq 'dd') {
		endtag($html, ['dt', 'dd'], 'dl');
		$ptag = $html->pos->tag;
		# Fix <dt> or <dd> outside <dl>
		$pos = $html->insertElement('dl', 1) unless $ptag eq 'dl';
	    } elsif ($isFormElement{$tag}) {
		return unless $pos->isInside('form');
		if ($tag eq 'option') {
		    # return unless $ptag eq 'select';
		    endtag($html, 'option');
		    $ptag = $html->pos->tag;
		    $pos = $html->insertElement('select', 1)
		      unless $ptag eq 'select';
		}
	    } elsif ($isTableElement{$tag}) {
		endtag($html, $tag, 'table');
		$pos = $html->insertElement('table', 1)
		  if !$pos->isInside('table');
	    } elsif ($isPhraseMarkup{$tag}) {
		if ($ptag eq 'body') {
		    $pos = $html->insertElement('p', 1);
		}
	    }
	} elsif ($isHeadElement{$tag}) {
	    if ($pos->isInside('body')) {
		warn "Header element <$tag> in body\n";
	    } elsif (!$pos->isInside('head')) {
		$pos = $html->insertElement('head', 1);
	    }
	} elsif ($tag eq 'html') {
	    if ($ptag eq 'html' && $pos->isEmpty()) {
		# migrate attributes to origial HTML element
		for (keys %attr) {
		    $html->attr($_, $attr{$_});
		}
		return;
	    } else {
		warn "Skipping nested html element\n";
		return;
	    }
	} elsif ($tag eq 'head') {
	    if ($ptag ne 'html' && $pos->isEmpty()) {
		warn "Skipping nested <head> element\n";
		return;
	    }
	} elsif ($tag eq 'body') {
	    if ($pos->isInside('head')) {
		endtag($html, 'head');
	    } elsif ($ptag ne 'html') {
		warn "Skipping nested <body> element\n";
		return;
	    }
	} else {
	    # unknown tag
	    if ($IGNORE_UNKNOWN) {
		warn "Skipping $tag\n";
		return;
	    }
	}
	$html->insertElement($e);
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


sub text
{
    my $html = shift;
    my $pos = $html->{_pos};
    $pos = $html unless defined($pos);

    my @text = @_;
    HTML::Entities::decode(@text) unless $IGNORE_TEXT;

    if ($pos->isInside(qw(pre xmp listing))) {
	return if $IGNORE_TEXT;
	$pos->pushContent(@text);
    } else {
	my $empty = 1;
	for (@text) {
	    $empty = 0 if /\S/;
	}
	return if $empty;

	my $ptag = $pos->{_tag};
	if (!$IMPLICIT_TAGS) {
	    # don't change anything
	} elsif ($ptag eq 'head') {
	    endtag($html, 'head');
	    $html->insertElement('body', 1);
	    $pos = $html->insertElement($html, 'p', 1);
	} elsif ($ptag eq 'html') {
	    $html->insertElement($html, 'body', 1);
	    $pos = $html->insertElement('p', 1);
	} elsif ($ptag eq 'body' ||
	       # $ptag eq 'li'   ||
	       # $ptag eq 'dd'   ||
		 $ptag eq 'form') {
	    $pos = $html->insertElement('p', 1);
	}
	return if $IGNORE_TEXT;
	for (@text) {
	    next if /^\s*$/;  # empty text
	    s/\s+/ /g;  # canoncial space
	    $pos->pushContent($_);
	}
    }
}


1;
