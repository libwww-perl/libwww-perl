print "1..1\n";


require HTML::Parser;

package P; @ISA = qw(HTML::Parser);

sub start
{
    my($self, $tag, $attr) = @_;
    print "START[$tag]\n";
    for (keys %$attr) {
	print "\t$_: $attr->{$_}\n";
    }
    $start++;
}

sub end
{
    my($self, $tag) = @_;
    print "END[$tag]\n";
    $end++;
}

sub text
{
    my $self = shift;
    print "TEXT[$_[0]]\n";
    $text++;
}

sub comment
{
    my $self = shift;
    print "COMMENT[$_[0]]\n";
    $comment++;
}

sub declaration
{
    my $self = shift;
    print "DECLARATION[$_[0]]\n";
    $declaration++;
}

package main;


@tests =
(
   "2 < 5",
   "2 <5> 2",
   "2 <a",
   "2 <a> 2",
   "2 <a href=foo",
   "2 <a href='foo bar'> 2",
   "2 <a href=foo bar> 2",
   "2 <a href=\"foo bar\"> 2",
   "2 <a href=\"foo'bar\"> 2",
   "2 <a href='foo\"bar'> 2",
   "2 <a href='foo&quot;bar'> 2",
   "2 <a.b> 2",
   "2 <a.b-12 a.b = 2 a> 2",
   "2 <a_b> 2",

   '<!ENTITY nbsp   CDATA "&#160;" -- no-break space -->',
   '<!-- comment -->',
   '<!-- comment -- -- comment -->',
   '<!-- comment <!-- not comment --> comment -->',
   '<!-- <a href="foo"> -->',
);


for (@tests) {
   $p = new P;
   #$p->netscape_buggy_comment(1);
   print "-" x 50, "\n";
   print "$_\n";
   print "-" x 50, "\n";
   
   $p->parse($_);
   $p->eof;

   print "\n";
}

print "THIS IS NOT REALLY A TEST YET\n";
print "ok 1\n";
