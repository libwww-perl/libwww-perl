package HTML::Parse;

# $Id: Parse.pm,v 1.2 1995/09/05 13:05:32 aas Exp $

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(parse parsefile);

require HTML::Element;

$IMPLICIT = 1;
$SPLIT_TEXT = 0;
$IGNORE_UNKNOWN = 1;

# Elements that should only be present in the header
for (qw(title base link meta isindex nextid)) {
    $isHeadElement{$_} = 1;
}

# Elements that should only be present in the body
for (qw(h1 h2 h3 h4 h5 h6
	p pre address blockquote
	a img br hr
	ol ul dir menu li
	dl dt dd
	cite code em kbd samp strong var
	b i u tt
	table tr td th caption
	form input select option textarea
       )
    ) {
    $isBodyElement{$_} = 1;
}

# Also parse some Netscape extentions elements
for (qw(wbr nobr center blink font basefont)) {
    $isBodyElement{$_} = 1;
}

# Lists
for (qw(ul ol dir menu)) {
    $isList{$_} = 1;
}

# Table elements
for (qw(tr td th caption)) {
    $isTableElement{$_} = 1;
}

# Form element
for (qw(input select option textarea)) {
    $isFormElement{$_} = 1;
}

%entities = (

 'lt'     => '<',
 'gt'     => '>',
 'amp'    => '&',
 'quot'   => '"',
 'nbsp'   => "\240",

 'Aacute' => 'Á',
 'Acirc'  => 'Â',
 'Agrave' => 'À',
 'Aring'  => 'Å',
 'Atilde' => 'Ã',
 'Auml'   => 'Ä',
 'Ccedil' => 'Ç',
 'ETH'    => 'Ð',
 'Eacute' => 'É',
 'Ecirc'  => 'Ê',
 'Egrave' => 'È',
 'Euml'   => 'Ë',
 'Iacute' => 'Í',
 'Icirc'  => 'Î',
 'Igrave' => 'Ì',
 'Iuml'   => 'Ï',
 'Ntilde' => 'Ñ',
 'AElig'  => 'Æ',
 'Oacute' => 'Ó',
 'Ocirc'  => 'Ô',
 'Ograve' => 'Ò',
 'Oslash' => 'Ø',
 'Otilde' => 'Õ',
 'Ouml'   => 'Ö',
 'THORN'  => 'Þ',
 'Uacute' => 'Ú',
 'Ucirc'  => 'Û',
 'Ugrave' => 'Ù',
 'Uuml'   => 'Ü',
 'Yacute' => 'Ý',
 'aelig'  => 'æ',
 'aacute' => 'á',
 'acirc'  => 'â',
 'agrave' => 'à',
 'aring'  => 'å',
 'atilde' => 'ã',
 'auml'   => 'ä',
 'ccedil' => 'ç',
 'eacute' => 'é',
 'ecirc'  => 'ê',
 'egrave' => 'è',
 'eth'    => 'ð',
 'euml'   => 'ë',
 'iacute' => 'í',
 'icirc'  => 'î',
 'igrave' => 'ì',
 'iuml'   => 'ï',
 'ntilde' => 'ñ',
 'oacute' => 'ó',
 'ocirc'  => 'ô',
 'ograve' => 'ò',
 'oslash' => 'ø',
 'otilde' => 'õ',
 'ouml'   => 'ö',
 'szlig'  => 'ß',
 'thorn'  => 'þ',
 'uacute' => 'ú',
 'ucirc'  => 'û',
 'ugrave' => 'ù',
 'uuml'   => 'ü',
 'yacute' => 'ý',
 'yuml'   => 'ÿ',

);


sub parse
{
    my $html = $_[1];
    $html = new HTML::Element 'html' unless defined $html;
    my $buf = \ $html->{'_buf'};
    $$buf .= $_[0];

    # Handle comments
    if ($html->{_comment}) {
	if ($$buf =~ s/.*-->//s) {        # end of comment
	    delete $html->{_comment};
	} else {
	    $$buf = '';          # still inside comment
	}
    }
    $$buf =~ s/<!--.*?-->//s;    # remove complete comments
    if ($$buf =~ s/<!--.*//s) {  # check for start of comment
	$html->{_comment} = 1;
    }
    return $html unless length $$buf;
    
    my @x = split(/(<[^>]+>)/, $$buf);
    if ($x[-1] =~ s/(<.*)//s) {
	$$buf = $1;
	pop(@x) unless length $x[-1];
    } else {
	$$buf = '';
    }
    for (@x) {
	if (m:^</:) {
	    endtag($html, $_);
	} elsif (m/^<\s*\w+/) {
	    starttag($html, $_);
	} elsif (m/^<!DOCTYPE\b/) {
	    # just ignore it
	} else {
	    text($html, $_);
	}
    }
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
		expandEntities($val);
	    } else {
		# boolean attribute
		$val = $key;
	    }
	    $attr{$key} = $val;
        }

	my $pos  = $html->pos;
	my $ptag = $pos->tag;
	my $e = new HTML::Element $tag, %attr;

        if (!$IMPLICIT) {
	    # do nothing
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
	} elsif ($isHeadElement{$tag}) {
	    if ($pos->isInside('body')) {
		warn "Header element <$tag> in body\n";
	    } elsif (!$pos->isInside('head')) {
		$pos = insertTag($html, 'head', 1);
	    }
        } elsif ($isBodyElement{$tag}) {
	    if ($pos->isInside('head')) {
		endtag($html, 'head');
		$pos = insertTag($html, 'body');
		$ptag = $pos->tag;
	    } elsif (!$pos->isInside('body')) {
		$pos = insertTag($html, 'body');
		$ptag = $pos->tag;
	    }

	    # Handle implicit endings and insert based on <tag> and position
	    if ($tag eq 'p' || $tag =~ /^h[1-6]/) {
		# Can't have <p> or <h#> inside these
		for (qw(p h1 h2 h3 h4 h5 h6 pre textarea)) {
		    endtag($html, $_);
		}
	    } elsif ($tag =~ /^[oud]l$/) {
		# Can't have lists inside <h#>
		if ($ptag =~ /^h[1-6]/) {
		    endtag($html, $ptag);
		    $pos = insertTag($html, 'p');
		    $ptag = 'p';
		}
	    } elsif ($tag eq 'li') {
		# Fix <li> outside list
		endtag($html, 'li');
		$ptag = $html->pos->tag;
		$pos = insertTag($html, 'ul') unless $isList{$ptag};
	    } elsif ($tag eq 'dt' || $tag eq 'dd') {
		endtag($html, 'dt');
		endtag($html, 'dd');
		$ptag = $html->pos->tag;
		# Fix <dt> or <dd> outside <dl>
		$pos = insertTag($html, 'dl') unless $ptag eq 'dl';
	    } elsif ($isFormElement{$tag}) {
		return unless $pos->isInside('form');
		if ($tag eq 'option') {
		    endtag($html, 'option');
		    $ptag = $html->pos->tag;
		    $pos = insertTag($html, 'select') unless $ptag eq 'select';
		}
	    }

	} else {
	    # unknown tag
	    if ($IGNORE_UNKNOWN) {
		warn "Skipping $tag\n";
		return;
	    }
	}
	insertTag($html, $e);
    }
}

sub insertTag
{
    my($html, $tag, $implicit) = @_;
    my $e;
    if (ref $tag) {
	$e = $tag;
	$tag = $e->tag;
    } else {
	$e = new HTML::Element $tag;
    }
    $e->implicit(1) if $implicit;
    my $pos = $html->pos;
    $e->parent($pos);
    $pos->pushContent($e);
    $html->pos($e) unless $HTML::Element::noEndTag{$tag};
    $html->pos;
}

sub endtag
{
    my $html = shift;
    my($tag) = $_[0] =~ m|^(?:</)?(\w+)>?$|;
    unless (defined $tag) {
	warn "Illegal end tag $_[0]";
    } else {
	#print "END: $tag\n";
	$tag = lc $tag;
	my $p = $html->pos;
	while (defined $p and $p->tag ne $tag) {
	    $p = $p->parent;
	}
	$html->pos($p->parent) if defined $p;
    }
}

sub text
{
    my $html = shift;
    my $pos = $html->pos;

    my @text = @_;
    expandEntities(@text);

    if ($pos->isInside('pre')) {
	$pos->pushContent(@text);
    } else {
	my $empty = 1;
	for (@text) {
	    $empty = 0 if /\S/;
	}
	return if $empty;

	my $ptag = $pos->tag;
	if ($ptag eq 'head') {
	    endtag($html, 'head');
	    insertTag($html, 'body');
	    $pos = insertTag($html, 'p');
	} elsif ($ptag eq 'html') {
	    insertTag($html, 'body');
	    $pos = insertTag($html, 'p');
	} elsif ($ptag eq 'body' ||
		 $ptag eq 'li'   ||
		 $ptag eq 'dd'   ||
		 $ptag eq 'form') {
	    $pos = insertTag($html, 'p');
	}
	for (@text) {
	    next if /^\s*$/;  # empty text
	    if ($SPLIT_TEXT) {
		$pos->pushContent(split(' ', $_));
	    } else {
		s/\s+/ /g;  # canoncial space
		$pos->pushContent($_);
	    }
	}
    }
}

sub expandEntities
{
    for (@_) {
	s/(&\#(\d+);?)/$2 < 256 ? chr($2) : $1/eg;
	s/(&(\w+);?)/$entities{$2} || $1/eg;
    }
}


sub parsefile
{
    my $file = shift;
    open(F, $file) or return new HTML::Element 'html', 'comment' => $!;
    my $html = undef;
    while(<F>) {
	$html = parse($_, $html);
    }
    close(F);
    $html;
}

1;
