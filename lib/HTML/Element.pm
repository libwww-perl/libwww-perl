package HTML::Element;

# $Id: Element.pm,v 1.3 1995/09/05 14:33:35 aas Exp $

=head1 NAME

HTML::Element - Ditto

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
sequence of text segments and other HTML::Element objects.

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut


use Carp;

# Elements that does not have corresponding end tags
for (qw(base link meta isindex nextid
	img br nobr wbr hr
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


sub new
{
    my $class = shift;
    my $tag   = shift;
    croak "No tag" unless defined $tag or length $tag;
    my $self  = bless { _tag => lc $tag }, $class;
    my($attr, $val);
    while (($attr, $val) = splice(@_, 0, 2)) {
	$val = 1 unless defined $val;
	$self->{lc $attr} = $val;
    }
    if ($tag eq 'html') {
	$self->{'_buf'} = '';
	$self->{'_pos'} = undef;
    }
    $self;
}

sub tag
{
    shift->{_tag};
}

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

sub endtag
{
    "</\U$_[0]->{_tag}>";
}


sub parent
{
    shift->attr('_parent', @_);
}

sub implicit
{
    shift->attr('_implicit', @_);
}
sub isInside
{
    my($self, $tag) = @_;
    my $p = $self;
    while (defined $p) {
	return 1 if $p->tag eq $tag;
	$p = $p->parent;
    }
    0;
}

sub pos
{
    my $self = shift;
    my $pos = $self->attr('_pos', @_);
    $pos || $self;
}

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

sub content
{
    shift->{'_content'};
}

sub isEmpty
{
    my $self = shift;
    !exists($self->{'_content'}) || !@{$self->{'_content'}};
}

sub pushContent
{
    my $self = shift;
    $self->{'_content'} = [] unless exists $self->{'_content'};
    push(@{$self->{'_content'}}, @_);
    $self;
}

sub deleteContent
{
    my $self = shift;
    for (@{$self->{'_content'}}) {
	$_->delete if ref $_;
    }
    delete $self->{'_content'};
    $self;
}

sub delete
{
    $_[0]->deleteContent;
    delete $_[0]->{_parent};
    delete $_[0]->{_pos};
    $_[0] = undef;
}

sub traverse
{
    my($self, $callback, $ignoretext, $depth) = @_;
    $depth |= 0;

    &$callback($self, $depth);
    for (@{$self->{'_content'}}) {
	if (ref $_) {
	    $_->traverse($callback, $ignoretext, $depth+1);
	} else {
	    &$callback($_, $depth+1) unless $ignoretext;
	}
    }
    $self;
}

sub extractLinks
{
    my $self = shift;
    my %wantType; @wantType{map { lc $_ } @_} = (1) x @_;
    my $wantType = scalar(@_);
    my @links;
    $self->traverse(
	sub {
	    my $self = shift;
	    my $tag = $self->tag;
	    return unless !$wantType || $wantType{$tag};
	    my $attr = $linkElements{$tag};
	    return unless defined $attr;
	    $attr = $self->attr($attr);
	    return unless defined $attr;
	    if (@types) {
		
	    }
	    push(@links, [$attr, $self]);
	}, 1);
    \@links;
}

sub dump
{
    my $self = shift;
    my $depth = shift || 0;
    print "  " x $depth;
    print $self->starttag, "\n";
    for (@{$self->{_content}}) {
	if (ref $_) {
	    $_->dump($depth+1);
	} else {
	    print "  " x ($depth + 1);
	    print qq{"$_"\n};
	}
    }
}

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
		while (s/^(.{60,}?)\s//) {
		    $html .= "\n" . ("  " x ($depth+1)) . $1;
		}
		$html .= "\n" . ("  " x ($depth+1)) . $_;
		$pos = length $_;
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


1;
