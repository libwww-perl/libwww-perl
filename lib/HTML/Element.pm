package HTML::Element;

# $Id: Element.pm,v 1.29 1996/05/09 09:22:45 aas Exp $

=head1 NAME

HTML::Element - Class for objects that represent HTML elements

=head1 SYNOPSIS

 require HTML::Element;
 $a = new HTML::Element 'a', href => 'http://www.oslonett.no/';
 $a->push_content("Oslonett AS");

 $tag = $a->tag;
 $tag = $a->starttag;
 $tag = $a->endtag;
 $ref = $a->attr('href');

 $links = $a->extract_links();

 print $a->as_HTML;

=head1 DESCRIPTION

Objects of the HTML::Element class can be used to represent elements
of HTML.  Objects have attributes and content.  The content is a
sequence of text segments and other HTML::Element objects.  Thus a
tree of HTML::Element objects as nodes can represent the syntax tree
for a HTML document.

The following methods are available:

=cut


use Carp;

$VERSION = sprintf("%d.%02d", q$Revision: 1.29 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

# Elements that does not have corresponding end tags
%noEndTag = map { $_ => 1 } qw(base link meta isindex nextid
			       img br hr wbr
			       input
			      );
%optionalEndTag = map { $_ => 1 } qw(p li dt dd option);

# Link elements an the name of the link attribute
%linkElements =
(
 body   => 'background',
 base   => 'href',
 a      => 'href',
 img    => 'src',
 form   => 'action',
 'link' => 'href',   # need quotes since link is a perl builtin
 frame  => 'src',
);



=head2 $h = new HTML::Element 'tag', 'attrname' => 'value',...

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



=head2 $h->tag()

Returns (optionally sets) the tag name for the element.

=cut

sub tag
{
    my $self = shift;
    if (@_) {
	$self->{_tag} = $_[0];
    } else {
	$self->{_tag};
    }
}



=head2 $h->starttag()

Returns the complete start tag for the element.  Including <> and attributes.

=cut

sub starttag
{
    my $self = shift;
    my $tag = "<\U$self->{_tag}";
    for (sort keys %$self) {
	next if /^_/;
	my $val = $self->{$_};
	if ($_ eq $val) {   # not always good enough (perhaps a very special
                            # value is better)
	    $tag .= " \U$_";
	} else {
	    $val =~ s/([&\">])/"&#" . ord($1) . ";"/eg;
	    $val = qq{"$val"} unless $val =~ /^\d+$/;
	    $tag .= qq{ \U$_\E=$val};
	}
    }
    "$tag>";
}



=head2 $h->endtag()

Returns the complete end tag.

=cut

sub endtag
{
    "</\U$_[0]->{_tag}>";
}



=head2 $h->parent([$newparent])

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



=head2 $h->implicit([$bool])

Returns (optionally sets) the implicit attribute.  This attribute is
used to indicate that the element was not originally present in the
source, but was inserted in order to conform to HTML strucure.

=cut

sub implicit
{
    shift->attr('_implicit', @_);
}



=head2 $h->is_inside('tag',...)

Returns true if this tag is contained inside one of the specified tags.

=cut

sub is_inside
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



=head2 $h->pos()

Returns (and optionally sets) the current position.  The position is a
reference to a HTML::Element object that is part of the tree that has
the current object as root.

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



=head2 $h->attr('attr', [$value])

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



=head2 $h->content()

Returns the content of this element.  The content is represented as a
array of text segments and references to other HTML::Element objects.

=cut

sub content
{
    shift->{'_content'};
}



=head2 $h->is_empty()

Returns true if there is no content.

=cut

sub is_empty
{
    my $self = shift;
    !exists($self->{'_content'}) || !@{$self->{'_content'}};
}



=head2 $h->insert_element($element, $implicit)

Inserts a new element at current position and sets the pos.

=cut

sub insert_element
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
    $pos->push_content($e);
    unless ($noEndTag{$tag}) {
	$self->{_pos} = $e;
	$pos = $e;
    }
    $pos;
}


=head2 $h->push_content($element)

Adds to the content of the element.  The content should be a text
segment (scalar) or a reference to a HTML::Element object.

=cut

sub push_content
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



=head2 $h->delete_content()

Clears the content.

=cut

sub delete_content
{
    my $self = shift;
    for (@{$self->{'_content'}}) {
	$_->delete if ref $_;
    }
    delete $self->{'_content'};
    $self;
}



=head2 $h->delete()

Frees memory assosiated with the element an all children.  This is
needed because perl's reference counting does not work since we use
circular references.

=cut
#'

sub delete
{
    $_[0]->delete_content;
    delete $_[0]->{_parent};
    delete $_[0]->{_pos};
    $_[0] = undef;
}



=head2 $h->traverse(\&callback, [$ignoretext])

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



=head2 $h->extract_links([@wantedTypes])

Returns links found by traversing the element and all its children.
The return value is a reference to an array.  Each element of the
array is an array with 2 values; the link value and a reference to the
corresponding element.

You might specify that you just want to extract some types of links.
For instance if you only want to extract <a href="..."> and <img
src="..."> links you might code it like this:

  for (@{ $e->extract_links(qw(a img)) }) {
      ($link, $linkelem) = @$_;
      ...
  }

=cut

sub extract_links
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



=head2 $h->dump()

Prints the element and all its children to STDOUT.  Mainly useful for
debugging.  The structure of the document is shown by indentation (no
end tags).

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



=head2 $h->as_HTML()

Returns a string (the HTML document) that represents the element and
its children.

=cut

sub as_HTML
{
    my $self = shift;
    my @html = ();
    $self->traverse(
        sub {
	    my($node, $start, $depth) = @_;
	    if (ref $node) {
		my $tag = $node->tag;
		if ($start) {
		    push(@html, $node->starttag);
		} elsif (not ($noEndTag{$tag} or $optionalEndTag{$tag})) {
		    push(@html, $node->endtag);
		}
	    } else {
		# simple text content
		HTML::Entities::encode_entities($node, "<>&");
		push(@html, $node);
	    }
        }
    );
    join('', @html, "\n");
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


=head1 COPYRIGHT

Copyright 1995,1996 Gisle Aas.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@sn.no>

=cut
