package HTML::Element;

# $Id: Element.pm,v 1.18 1995/09/15 17:04:16 aas Exp $

=head1 NAME

HTML::Element - Class for objects that represent HTML elements

=head1 SYNOPSIS

 require HTML::Element;
 $a = new HTML::Element 'a', href => 'http://www.oslonett.no/';
 $a->pushContent("Oslonett AS");

 $tag = $a->tag;
 $tag = $a->starttag;
 $tag = $a->endtag;
 $ref = $a->attr('href');

 $links = $a->extractLinks();

 print $a->asHTML;

=head1 DESCRIPTION

Objects of the HTML::Element class can be used to represent elements
of HTML.  Objects have attributes and content.  The content is a
sequence of text segments and other HTML::Element objects.  Thus a
tree of HTML::Element objects as nodes can represent the syntax tree
for a HTML document.

The following methods are available:

=over 4

=cut


use Carp;

$VERSION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

%OVERLOAD =
(
   '""'     => 'asHTML',
   fallback => 0
);

# Elements that does not have corresponding end tags
for (qw(base link meta isindex nextid
	img br hr wbr
	input
       )
    ) {
    $noEndTag{$_} = 1;
}

# Link elements an the name of the link attribute
%linkElements =
(
 'base' => 'href',
 'a'    => 'href',
 'img'  => 'src',
 'from' => 'action',
 'link' => 'href',
);



=item new HTML::Element 'tag', 'attrname' => 'value',...

The object constructor.  Takes an tag name as argument. Optionally
allows you to specify initial attributes at object creation time.

=cut

sub new
{
    my $class = shift;
    my $tag   = shift;
    croak "No tag" unless defined $tag or length $tag;
    my $self  = bless { _tag => lc $tag }, $class;
    my($attr, $val);
    while (($attr, $val) = splice(@_, 0, 2)) {
	$val = $attr unless defined $val;
	$self->{lc $attr} = $val;
    }
    if ($tag eq 'html') {
	$self->{'_buf'} = '';
	$self->{'_pos'} = undef;
    }
    $self;
}



=item ->tag()

Returns the tag name for the element.

=cut

sub tag
{
    shift->{_tag};
}



=item ->starttag()

Returns the complete start tag for the element.  Including <> and attributes.

=cut

sub starttag
{
    my $self = shift;
    my $tag = "<\U$self->{_tag}";
    for (sort keys %$self) {
	next if /^_/;
	my $val = $self->{$_};
	if ($_ eq $val) {
	    $tag .= " \U$_";
	} else {
	    $val =~ s/([\">])/"&#" . ord($1) . ";"/eg;
	    $val = qq{"$val"} unless $val =~ /^\d+$/;
	    $tag .= qq{ \U$_\E=$val};
	}
    }
    "$tag>";
}



=item ->endtag()

Returns the complete end tag.

=cut

sub endtag
{
    "</\U$_[0]->{_tag}>";
}



=item ->parent([$newparent])

Returns (optionally sets) the parent for this element.

=cut

sub parent
{
    my $self = shift;
    if (@_) {
	$self->{'_parent'} = $_[0];
    } else {
	$self->{'_parent'};
    }
}



=item ->implicit([$bool])

Returns (optionally sets) the implicit attribute.  This attribute is
used to indicate that the element was not originally present in the
source, but was inserted in order to conform to HTML strucure.

=cut

sub implicit
{
    shift->attr('_implicit', @_);
}



=item ->isInside('tag',...)

Returns true if this tag is contained inside one of the specified tags.

=cut

sub isInside
{
    my $self = shift;
    my $p = $self;
    while (defined $p) {
	my $ptag = $p->{'_tag'};
	for (@_) {
	    return 1 if $ptag eq $_;
	}
	$p = $p->{'_parent'};
    }
    0;
}



=item ->pos()

Returns (and optionally sets) the current position.

=cut

sub pos
{
    my $self = shift;
    my $pos = $self->{_pos};
    if (@_) {
	$self->{_pos} = $_[0];
    }
    return $pos if defined($pos);
    $self;
}



=item ->attr('attr', [$value])

Returns (and optionally sets) the value of some attribute.

=cut

sub attr
{
    my $self = shift;
    my $attr = lc shift;
    my $old = $self->{$attr};
    if (@_) {
	$self->{$attr} = $_[0];
    }
    $old;
}



=item ->content()

Returns the content of this element.  The content is represented as a
array of text segments and references to other HTML::Element objects.

=cut

sub content
{
    shift->{'_content'};
}



=item ->isEmpty()

Returns true if there is no content.

=cut

sub isEmpty
{
    my $self = shift;
    !exists($self->{'_content'}) || !@{$self->{'_content'}};
}



=item ->insertElement($element, $implicit)

Inserts a new element at current position and sets the pos.

=cut

sub insertElement
{
    my($self, $tag, $implicit) = @_;
    my $e;
    if (ref $tag) {
	$e = $tag;
	$tag = $e->tag;
    } else {
	$e = new HTML::Element $tag;
    }
    $e->{_implicit} = 1 if $implicit;
    my $pos = $self->{_pos};
    $pos = $self unless defined $pos;
    $e->{_parent} = $pos;
    $pos->pushContent($e);
    unless ($noEndTag{$tag}) {
	$self->{_pos} = $e;
	$pos = $e;
    }
    $pos;
}


=item ->pushContent($element)

Adds to the content of the element.  The content should be a text
segment (scalar) or a reference to a HTML::Element object.

=cut

sub pushContent
{
    my $self = shift;
    $self->{'_content'} = [] unless exists $self->{'_content'};
    my $content = $self->{'_content'};
    if (@$content && !ref $content->[-1]) {  # last element is a text segment
	if (ref $_[0]) {
	    push(@$content, @_);
	} else {
	    # just join the text segments together
	    $content->[-1] .= $_[0];
	}
    } else {
       push(@$content, @_);
    }
    $self;
}



=item ->deleteContent()

Clears the content.

=cut

sub deleteContent
{
    my $self = shift;
    for (@{$self->{'_content'}}) {
	$_->delete if ref $_;
    }
    delete $self->{'_content'};
    $self;
}



=item ->delete()

Frees memory assosiated with the element an all children.  This is
needed because perl's reference counting does not work since we use
circular references.

=cut
#'

sub delete
{
    $_[0]->deleteContent;
    delete $_[0]->{_parent};
    delete $_[0]->{_pos};
    $_[0] = undef;
}



=item ->traverse(\&callback, [$ignoretext])

Traverse the element and all its children.  For each node visited, the
callback routine is called with the node, a startflag and the depth as
arguments.  If the $ignoretext parameter is true, then the callback
will not be called for text content.  The flag is 1 when we enter a
node and 0 when we leave the node.

If the return value from the callback is false then we will not
traverse the children.

=cut

sub traverse
{
    my($self, $callback, $ignoretext, $depth) = @_;
    $depth ||= 0;

    if (&$callback($self, 1, $depth)) {
	for (@{$self->{'_content'}}) {
	    if (ref $_) {
		$_->traverse($callback, $ignoretext, $depth+1);
	    } else {
		&$callback($_, 1, $depth+1) unless $ignoretext;
	    }
	}
	&$callback($self, 0, $depth) unless $noEndTag{$self->{_tag}};
    }
    $self;
}



=item ->extractLinks([@wantedTypes])

Returns links found by traversing the element and all its children.
The return value is a reference to an array.  Each element of the
array is an array with 2 values; the link value and a reference to the
corresponding element.

You might specify that you just want to extract some types of links.
For instance if you only want to extract <a href="..."> and <img
src="..."> links you might code it like this:

  for (@{ $e->extractLinks(qw(a img)) }) {
      ($link, $linkelem) = @$_;
      ...
  }

=cut

sub extractLinks
{
    my $self = shift;
    my %wantType; @wantType{map { lc $_ } @_} = (1) x @_;
    my $wantType = scalar(@_);
    my @links;
    $self->traverse(
	sub {
	    my($self, $start, $depth) = @_;
	    return 1 unless $start;
	    my $tag = $self->{'_tag'};
	    return 1 if $wantType && !$wantType{$tag};
	    my $attr = $linkElements{$tag};
	    return 1 unless defined $attr;
	    $attr = $self->attr($attr);
	    return 1 unless defined $attr;
	    push(@links, [$attr, $self]);
	    1;
	}, 1);
    \@links;
}



=item ->dump()

Prints the element and all its children to STDOUT.  Mainly useful for
debugging.

=cut

sub dump
{
    my $self = shift;
    my $depth = shift || 0;
    print STDERR "  " x $depth;
    print STDERR $self->starttag, "\n";
    for (@{$self->{_content}}) {
	if (ref $_) {
	    $_->dump($depth+1);
	} else {
	    print STDERR "  " x ($depth + 1);
	    print STDERR qq{"$_"\n};
	}
    }
}



=item ->asHTML()

Retuns a string (the HTML document) that represents the element and
its children.

=cut

sub asHTML
{
    my $self = shift;
    my $depth = shift || 0;
    my $tag = $self->tag;
    my $pre = $self->isInside('pre');
    my $html = '';
    $html .= "  " x $depth unless $pre;
    $html .= $self->starttag;

    my $pos = 0;

    for (@{$self->{_content}}) {
	if (ref $_) {
	    $html .= "\n" unless $pre;
	    $html .= $_->asHTML($depth+1);
	} else {
	    if ($pre) {
		$html .= "$_";
	    } else {
		if ($pos + length $_ < 60) {
		    $html .= $_;
		    $pos += length $_;
		    next;
		}
		my $copy = $_;
		while ($copy =~ s/^(.{60,}?)\s//) {
		    $html .= "\n" . ("  " x ($depth+1)) . $1;
		}
		$html .= "\n" . ("  " x ($depth+1)) . $copy;
		$pos = length $copy;
	    }
	}
    }
    unless ($noEndTag{$tag} || $tag eq 'p') {
	unless ($pre) {
	    $html .= "\n";
	    $html .= "  " x $depth;
	}
	$html .= $self->endtag;
    }
    $html .= "\n" if $depth == 0;
    $html;
}

sub format
{
    my($self, $formatter) = @_;
    unless (defined $formatter) {
	require HTML::FormatText;
	$formatter = new HTML::FormatText;
    }
    $formatter->format($self);
}


1;

__END__

=back

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut
