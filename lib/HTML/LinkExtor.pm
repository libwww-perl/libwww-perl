package HTML::LinkExtor;

=head1 NAME

HTML::LinkExtor - Extract links from an HTML document

=head1 SYNPOSIS

 $p = HTML::LinkExtor->new(\&cb, "http://www.sn.no/");
 sub cb {
     my($tag, %links);
     print "$tag @{[%links]}\n";
 }
 $p->parsefile("index.html");

=head1 DESCRIPTION

The I<HTML::LinkExtor> is a I<HTML::Parser> that calls a callback
routine as various link attributes are recognized.

=cut

require HTML::Parser;
@ISA = qw(HTML::Parser);

use URI::URL qw(url);

use strict;
use vars qw(%LINK_ELEMENT);

# Elements that might contain links and the name of the link attribute
%LINK_ELEMENT =
(
 body   => 'background',
 base   => 'href',
 a      => 'href',
 img    => [qw(src lowsrc usemap)],   # lowsrc is a Netscape invention
 form   => 'action',
 input  => 'src',
'link'  => 'href',          # need quoting since link is a perl builtin
 frame  => 'src',
 applet => 'codebase',
 area   => 'href',
);

=head2 $p = HTML::LinkExtor->new($callback, $base)

The constructor takes two argument.  The first is a reference to a
callback routine.  It will be called as links are found.  If a
callback is not provided, then links are just accumulated internally
and can be retrieved by calling the $p->links() method.  The $base is
an optional base URL used to absolutize all URLs found.

The callback is called with the lowercase tag name as first argument,
and then all link attributes as separate key/value pairs.  All
non-link attributes are removed.

=cut

sub new
{
    my($class, $cb, $base) = @_;
    my $self = $class->SUPER::new;
    $self->{extractlink_cb} = $cb;
    $self->{extractlink_base} = $base;
    $self;
}

sub start
{
    my($self, $tag, $attr) = @_;  # $attr is reference to a HASH
    return unless exists $LINK_ELEMENT{$tag};

    my $base = $self->{extractlink_base};
    my $links = $LINK_ELEMENT{$tag};
    $links = [$links] unless ref $links;

    my @links;
    my $a;
    for $a (@$links) {
	next unless exists $attr->{$a};
	push(@links, $a, $base ? url($attr->{$a}, $base)->abs : $attr->{$a});
    }
    return unless @links;

    my $cb = $self->{extractlink_cb};
    if ($cb) {
	&$cb($tag, @links);
    } else {
	push(@{$self->{'links'}}, [$tag, @links]);
    }
}

=head2 @links = $p->links

Return links found in the document as a two dimentional array.  Each
element contain an array with the follwing values:

  [$tag, $attr1, $url1, $attr2, $url2,...]

Note that $p->links will always be empty if a callback routine was
provided.

=cut

sub links
{
    my $self = shift;
    @{$self->{'links'}}
}


=head1 SEE ALSO

L<HTML::Parser>

=head1 AUTHOR

Gisle Aas E<lt>aas@sn.no>

=cut

1;
