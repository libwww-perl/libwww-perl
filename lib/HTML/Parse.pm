package HTML::Parse;

# $Id: Parse.pm,v 2.0 1996/05/19 11:53:06 aas Exp $

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

=item $HTML::Parse::tree::IMPLICIT_TAGS

Setting this variable to true will instruct the parser to try to
deduce implicit elements and implicit end tags.  If this variable is
false you get a parse tree that just reflects the text as it stands.
Might be useful for quick & dirty parsing.  Default is true.

Implicit elements have the implicit() attribute set.

=item $HTML::Parse::tree::IGNORE_UNKNOWN

This variable contols whether unknow tags should be represented as
elements in the parse tree.  Default is true.

=item $HTML::Parse::tree::IGNORE_TEXT

Do not represent the text content of elements.  This saves space if
all you want is to examine the structure of the document.  Default is
false.

=item $HTML::Parse::tree::WARN

Call warn() with an apropriate message for syntax errors.  Default is
false.

=back


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

use strict;

use vars qw($VERSION);

require HTML::Element;
use HTML::Entities ();

$VERSION = sprintf("%d.%02d", q$Revision: 2.0 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }


# How does Netscape do it: It parse <xmp> in the depreceated 'literal'
# mode, i.e. no tags are recognized until a </xmp> is found.
# 
# <listing> is parsed like <pre>, i.e. tags are recognized.  <listing>
# are presentend in smaller font than <pre>
#
# Netscape does not parse this comment correctly (it terminates the comment
# too early):
#
#    <! -- comment -- --> more comment -->
#
# Netscape does not allow space after the initial "<" in the start tag.
# Like this "<a href='gisle'>"
#
# Netscape ignore '<!--' and '-->' within the <SCRIPT> tag.  This is used
# as a trick to make non-script-aware browsers ignore the scripts.


sub parse_html ($;$)
{
    my $p = $_[1];
    $p = HTML::Parse::tree->new unless $p;
    my $buf = \ $p->{'_buf'};
    $$buf .= $_[0];

    # Parse html text in $$buf.  The strategy is to remove complete
    # tokens from the beginning of $$buf until we can't deside whether
    # it is a token or not, or the $$buf is empty.
    while (1) {  # the loop will end by returning when text is parsed
	# First we try to pull off any plain text
	if ($$buf =~ s|^([^<]+)||) {
	    unless (length $$buf) {
		# At the end of the buffer, we should not parse white space
		# but leave it for parsing on the next round
		my $text = $1;
		$text =~ s|(\s*)$||;
		$$buf = $1;
		$p->text($text);
		return $p;
	    } else {
		$p->text($1);
	    }
	# Then, special tags (usually either <!DOCTYPE...> or a comment)
	} elsif ($$buf =~ s|^(<!)||) {
	    my $eaten = $1;
	    my $text = '';
	    # Eat text and beginning of comment
	    while ($$buf =~ s|^(([^>]*?)--)||) {
		$eaten .= $1;
		$text .= $2;
		# Look for end of comment
		if ($$buf =~ s|^((.*?)--)||s) {
		    $eaten .= $1;
		    $p->comment($2);
		} else {
		    # Need more data to get all comment text.  This might
		    # result in the comment callback being called more than
		    # once for the several comment data.
		    $$buf = $eaten . $$buf;
		    return $p;
		}
	    }
	    # Can we finish the tag
	    if ($$buf =~ s|^([^>]*)>||) {
		$text .= $1;
		$p->special($text) if $text =~ /\S/;
	    } else {
		$$buf = $eaten . $$buf;  # must start with it all next time
		return $p;
	    }
	# Then, look for a end tag
	} elsif ($$buf =~ s|^</||) {
	    # end tag
	    if ($$buf =~ s|^\s*([a-z]\w*)\s*>||i) {
		$p->end(lc($1));
	    } elsif ($$buf =~ m|^\s*[a-z]*\w*\s*$|i) {
		$$buf = "</" . $$buf;  # need more data to be sure
		return $p;
	    } else {
		# it is plain text after all
		$p->text($$buf);
		$$buf = "";
	    }
	# Then, finally we look for a start tag
	} elsif ($$buf =~ s|^(<\s*)||) {
	    # start tag
	    my $eaten = $1;

	    # This first thing we must find is a tag word
	    if ($$buf =~ s|^(([a-z]\w*)\s*)||i) {
		$eaten .= $1;
		my $tag = lc $2;
		my %attr;

		# Then we would like to find some attributes
		while ($$buf =~ s|^(([a-z]\w*)\s*)||i) {
		    $eaten .= $1;
		    my $attr = lc $2;
		    my $val = $attr;
		    # The attribute might take an optional value
		    if ($$buf =~ s|(^=\s*([^>\"\'][^>\s]*)\s*)||) { # unquoted
			$eaten .= $1;
			$val = $2;
			HTML::Entities::decode($val);
                     # or quoted by " or '
		     } elsif ($$buf =~ s|(^=\s*([\"\'])?([^\2]*)\2\s*)||) {
			$eaten .= $1;
			$val = $3;
			HTML::Entities::decode($val);
		    }
		    $attr{$attr} = $val;
		}

		# At the end there should be a closing ">"
		if ($$buf =~ s|^>||) {
		    $p->start($tag, \%attr);
		} elsif (length $$buf) {
		    # Not a conforming start tag, regard it as normal text
		    $p->text($eaten);
		} else {
		    $$buf = $eaten;  # need more data to know
		    return $p;
		}

	    } elsif (length $$buf) {
		$p->text($eaten);
	    } else {
		$$buf = $eaten . $$buf;  # need more data to parse
		return $p;
	    }

	} elsif (length $$buf) {
	    die; # This should never happen
	} else {
	    # The buffer is empty now
	    return $p;
	}
    }
    $p;
}


sub parse_htmlfile ($;$)
{
    my($file, $p) = @_;
    local(*HTML);
    open(HTML, $file) or return undef;
    my $chunk = '';
    while(read(HTML, $chunk, 2048)) {
	$p = parse_html($chunk, $p);
    }
    close(HTML);
    $p;
}



package HTML::Parse::base;

sub new
{
    my $class = shift;
    my $self = bless { '_buf' => '' }, $class;
    $self;
}

sub text
{
    # my($self, $text) = @_;
}

sub special
{
    # my($self, $special) = @_;
}

sub comment
{
    # my($self, $comment) = @_;
}

sub start
{
    my($self, $tag, $attr) = @_;  # $attr is reference to a HASH
}

sub end
{
    my($self, $tag) = @_;
}




package HTML::Parse::tree;

use vars qw(@ISA
            $IMPLICIT_TAGS $IGNORE_UNKNOWN $IGNORE_TEXT $WARN
            %isHeadElement %isBodyElement %isPhraseMarkup
            %isList %isTableElement %isFormElement
           );

@ISA = qw(HTML::Element HTML::Parse::base);

$IMPLICIT_TAGS  = 1;
$IGNORE_UNKNOWN = 1;
$IGNORE_TEXT    = 0;
$WARN           = 0;

sub warning ($)
{
    warn "HTML::Parse: $_[0]\n" if $WARN;
}


# Elements that should only be present in the header
%isHeadElement = map { $_ => 1 } qw(title base link meta isindex script);

# Elements that should only be present in the body
%isBodyElement = map { $_ => 1 } qw(h1 h2 h3 h4 h5 h6
				    p div pre address blockquote
				    xmp listing
				    a img br hr
				    ol ul dir menu li
				    dl dt dd
				    cite code em kbd samp strong var dfn strike
				    b i u tt small big
				    table tr td th caption
				    form input select option textarea
				    map area
				    applet param
				    isindex script
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


sub new
{
    my $class = shift;
    my $self = bless HTML::Element->new('html'), $class;
    $self->{'_buf'} = '';
    $self;
}


sub start ($$$)
{
    my($self, $tag, $attr) = @_;

    my $pos  = $self->{'_pos'};
    $pos = $self unless defined $pos;
    my $ptag = $pos->{'_tag'};
    my $e = HTML::Element->new($tag, %$attr);

    if (!$IMPLICIT_TAGS) {
	# do nothing
    } elsif ($isBodyElement{$tag}) {

	# Ensure that we are within <body>
	if ($pos->is_inside('head')) {
	    $self->end('head');
	    $pos = $self->insert_element('body', 1);
	    $ptag = $pos->tag;
	} elsif (!$pos->is_inside('body')) {
	    $pos = $self->insert_element('body', 1);
	    $ptag = $pos->tag;
	}

	# Handle implicit endings and insert based on <tag> and position
	if ($tag eq 'p' || $tag =~ /^h[1-6]/ || $tag eq 'form') {
	    # Can't have <p>, <h#> or <form> inside these
	    $self->end([qw(p h1 h2 h3 h4 h5 h6 pre textarea)], 'li');
	} elsif ($tag =~ /^[oud]l$/) {
	    # Can't have lists inside <h#>
	    if ($ptag =~ /^h[1-6]/) {
		$self->end($ptag);
		$pos = $self->insert_element('p', 1);
		$ptag = 'p';
	    }
	} elsif ($tag eq 'li') {
	    # Fix <li> outside list
	    $self->end('li', keys %isList);
	    $ptag = $self->pos->tag;
	    $pos = $self->insert_element('ul', 1) unless $isList{$ptag};
	} elsif ($tag eq 'dt' || $tag eq 'dd') {
	    $self->end(['dt', 'dd'], 'dl');
	    $ptag = $self->pos->tag;
	    # Fix <dt> or <dd> outside <dl>
	    $pos = $self->insert_element('dl', 1) unless $ptag eq 'dl';
	} elsif ($isFormElement{$tag}) {
	    return unless $pos->is_inside('form');
	    if ($tag eq 'option') {
		# return unless $ptag eq 'select';
		$self->end('option');
		$ptag = $self->pos->tag;
		$pos = $self->insert_element('select', 1)
		  unless $ptag eq 'select';
	    }
	} elsif ($isTableElement{$tag}) {
	    $self->end($tag, 'table');
	    $pos = $self->insert_element('table', 1)
	      if !$pos->is_inside('table');
	} elsif ($isPhraseMarkup{$tag}) {
	    if ($ptag eq 'body') {
		$pos = $self->insert_element('p', 1);
	    }
	}
    } elsif ($isHeadElement{$tag}) {
	if ($pos->is_inside('body')) {
	    warning "Header element <$tag> in body";
	} elsif (!$pos->is_inside('head')) {
	    $pos = $self->insert_element('head', 1);
	}
    } elsif ($tag eq 'html') {
	if ($ptag eq 'html' && $pos->is_empty()) {
	    # migrate attributes to origial HTML element
	    for (keys %$attr) {
		$self->attr($_, $attr->{$_});
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
	    $self->end('head');
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
    $self->insert_element($e);
}


sub end
{
    my($self, $tag, @stop) = @_;

    # End the specified tag, but don't move above any of the @stop tags.
    # The tag can also be a reference to an array.  Terminate the first
    # tag found.

    my $p = $self->{'_pos'};
    $p = $self unless defined($p);
    if (ref $tag) {
      PARENT:
	while (defined $p) {
	    my $ptag = $p->{'_tag'};
	    for (@$tag) {
		last PARENT if $ptag eq $_;
	    }
	    for (@stop) {
		return if $ptag eq $_;
	    }
	    $p = $p->{'_parent'};
	}
    } else {
	while (defined $p) {
	    my $ptag = $p->{'_tag'};
	    last if $ptag eq $tag;
	    for (@stop) {
		return if $ptag eq $_;
	    }
	    $p = $p->{'_parent'};
	}
    }

    # Move position if the specified tag was found
    $self->{'_pos'} = $p->{'_parent'} if defined $p;
}


sub text ($$)
{
    my $self = shift;
    my $pos = $self->{'_pos'};
    $pos = $self unless defined($pos);

    my $text = shift;
    return unless length $text;

    HTML::Entities::decode($text) unless $IGNORE_TEXT;

    if ($pos->is_inside(qw(pre xmp listing))) {
	return if $IGNORE_TEXT;
	$pos->push_content($text);
    } else {
	# return unless $text =~ /\S/;  # This is sometimes wrong

	my $ptag = $pos->{'_tag'};
	if (!$IMPLICIT_TAGS || $text !~ /\S/) {
	    # don't change anything
	} elsif ($ptag eq 'head') {
	    $self->end('head');
	    $self->insert_element('body', 1);
	    $pos = $self->insert_element('p', 1);
	} elsif ($ptag eq 'html') {
	    $self->insert_element('body', 1);
	    $pos = $self->insert_element('p', 1);
	} elsif ($ptag eq 'body' ||
	       # $ptag eq 'li'   ||
	       # $ptag eq 'dd'   ||
		 $ptag eq 'form') {
	    $pos = $self->insert_element('p', 1);
	}
	return if $IGNORE_TEXT;
	$text =~ s/\s+/ /g;  # canoncial space
	$pos->push_content($text);
    }
}

1;
