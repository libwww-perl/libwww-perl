package HTML::Element;

# $Id: Element.pm,v 1.2 1995/09/05 13:04:01 aas Exp $

use Carp;

# Elements that does not have corresponding end tags
for (qw(base link meta isindex nextid
	img br nobr wbr hr
	input
       )
    ) {
    $noEndTag{$_} = 1;
}

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
}

sub deleteContent
{
    my $self = shift;
    delete $self->{'_content'};
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
