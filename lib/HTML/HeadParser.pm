package HTML::HeadParser;

=head1 NAME

HTML::HeadParser - Parse <HEAD> section of a HTML document

=head1 SYNOPSIS

 require HTML::HeadParser;
 $p = HTML::HeadParser->new;
 $p->parse($text) and  print "not finished";

 $p->header('Title')  # to access <title>....</title>
 $p->header('Base')   # to access <base href="http://...">
 $p->header('Foo')    # to access <meta http-equiv="Foo" content="...">

=head1 DESCRIPTION

The C<HTML::HeadParser> is a specialized (and lightweight)
C<HTML::Parser> that will only parse the <HEAD>...</HEAD> section of a
HTML document.  The parse() and parse_file() method will return a
FALSE value as soon as a <BODY> element is found, and should not be
called again after this.

The C<HTML::HeadParser> constructor can also be called with a
HTTP::Headers object reference as argument.  This will make the parser
update this header object as the various head elements are recognized.
The following example illustrates this:

 $h = HTTP::Headers->new;
 $p = HTML::HeadParser->new($h);
 $p->parse(<<EOT);
 <title>Stupid example</title>
 <base href="http://www.sn.no/libwww-perl/">
 Normal text starts here.
 EOT
 undef $p;
 print $h->title;

The parse text can be supplied in arbitrary chunks to the parse()
method.

=head1 SEE ALSO

L<HTML::Parser>, L<HTTP::Headers>

=head1 COPYRIGHT

Copyright 1996 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@sn.no>

=cut

require HTML::Parser;
@ISA = qw(HTML::Parser);

use HTML::Entities ();
require HTTP::Headers;

use strict;
use vars qw($VERSION $DEBUG);
#$DEBUG = 1;
$VERSION = sprintf("%d.%02d", q$Revision: 2.1 $ =~ /(\d+)\.(\d+)/);

my $FINISH = "HEAD PARSED\n";

sub new
{
    my($class, $header) = @_;
    $header ||= HTTP::Headers->new;
    my $self = bless HTML::Parser->new, $class;
    $self->{'header'} = $header;
    $self->{'tag'} = '';   # name of active element that takes textual content
    $self->{'text'} = '';  # the accumulated text associated with the element
    $self;
}

sub parse
{
    my $self = shift;
    eval { $self->SUPER::parse(@_) };
    if ($@) {
        print $@ if $DEBUG;
	$self->{'_buf'} = '';  # flush rest of buffer
	return '';
    }
    $self;
}

sub header
{
    my $self = shift;
    $self->{'header'}->header(@_);
}

sub as_string
{
    my $self = shift;
    $self->{'header'}->as_string;
}

sub flush_text
{
    my $self = shift;
    my $tag  = $self->{'tag'};
    my $text = $self->{'text'};
    $text =~ s/^\s+//; 
    $text =~ s/\s+$//; 
    $text =~ s/\s+/ /g;
    print "FLUSH $tag => '$text'\n"  if $DEBUG;
    if ($tag eq 'title') {
	$self->{'header'}->header(title => $text);
    }
    $self->{'tag'} = $self->{'text'} = '';
}

# This is an quote from the HTML3.2 DTD which shows which elements
# that might be present in a <HEAD>...</HEAD>.  Also note that the
# <HEAD> tags themselves might be missing:
#
# <!ENTITY % head.content "TITLE & ISINDEX? & BASE? & STYLE? &
#                            SCRIPT* & META* & LINK*">
# 
# <!ELEMENT HEAD O O  (%head.content)>


sub start
{
    my($self, $tag, $attr) = @_;  # $attr is reference to a HASH
    print "START[$tag]\n" if $DEBUG;
    $self->flush_text if $self->{'tag'};
    if ($tag eq 'meta') {
	if (exists $attr->{'http-equiv'}) {
	    $self->{'header'}->push_header($attr->{'http-equiv'} =>
					   $attr->{content})
	}
    } elsif ($tag eq 'base') {
	$self->{'header'}->header(Base => $attr->{href});
    } elsif ($tag eq 'isindex') {
	$self->{'header'}->header(Isindex => $attr->{prompt} || '?');
    } elsif ($tag =~ /^(?:title|script|style)$/) {
	$self->{'tag'} = $tag;
    } elsif ($tag eq 'link') {
	#XXX: how shall we represent a link as a header?
	# <link href="http:..." rel="xxx" rev="xxx" title="xxx">
    } elsif ($tag eq 'head' || $tag eq 'html') {
	# ignore
    } else {
	die $FINISH;
    }
}

sub end
{
    my($self, $tag) = @_;
    print "END[$tag]\n" if $DEBUG;
    $self->flush_text if $self->{'tag'};
    die $FINISH if $tag eq 'head';
}

sub text
{
    my($self, $text) = @_;
    print "TEXT[$text]\n" if $DEBUG;
    my $tag = $self->{tag};
    if (!$tag && $text =~ /\S/) {
	# Normal text means start of body
	die $FINISH;
    }
    return if $tag ne 'title';  # optimize skipping of <script> and <style>
    HTML::Entities::decode($text);
    $self->{'text'} .= $text;
}

1;
