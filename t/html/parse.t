print "1..2\n";

use HTML::Parse;

# This is a very simple test.  It basically just ensures that the
# module is parsed ok by perl.

$HTML = <<'EOT';

<Title>Test page
</title>

<h1>Header</h1>

This is a link to
<a href="http://www.sn.no/">Schibsted</a> <b>Nett</b> in Norway.

<p>Sofie Amundsen var på vei hjem fra skolen.  Det første stykket
hadde hun gått sammen med Jorunn.  De hadde snakket om roboter.
Jorunn hadde ment at menneskets hjerne var som en komplisert
datamaskin.  Sofie var ikke helt sikker på om hun var enig.  Et
menneske m&aring;tte da være noe mer enn en maskin?


<!-- This is
a <strong>comment</strong>
<!--

-->

<p>
<table>
<tr><th colspan=2>Name
<tr><td>Aas<td>Gisle
<tr><td>Koster<td>Martijn
</table>

EOT


$h = parse_html $HTML;

# This ensures that the output from $h->dump goes to STDOUT
open(STDERR, '>&STDOUT');  # Redirect STDERR to STDOUT
print STDERR "\n";
$h->dump;

$html = $h->as_HTML;

# This is a very simple test just to ensure that we get something
# sensible back.
print "not " unless $html =~ /<BODY>/i && $html =~ /www\.sn\.no/
	         && $html !~ /comment/;

print "ok 1\n\n";

$h->delete;

# Now we use a shorter document, because we don't have all day on
# this.

$HTML = <<'EOT';

<Title>Test page
</title>

<h1>Header</h1>

<!-- Comment -->

Some text <b>bold</b> <i>italic</i>
EOT

$h = parse_html $HTML;
$html = $h->as_HTML;
$h->delete;

print $html;

$BAD = 0;
# This test tries to parse the when we split it in two.
for $pos (1 .. length($HTML) - 1) {
   $first = substr($HTML, 0, $pos);
   $last  = substr($HTML, $pos);
   die "This is bad" unless $HTML eq ($first . $last);
   $h = parse_html($first);
   $h = parse_html($last, $h);
   $new_html = $h->as_HTML;
   if ($new_html ne $html) {
      print "\n\nSomething is different when splitting at position $pos:\n";
      $before = 10;
      $before = $pos if $pos < $before;
      print "«", substr($HTML, $pos - $before, $before);
      print "»\n«";
      print substr($HTML, $pos, 10);
      print "»\n";
      print "\n$html$new_html\n";
      $BAD = 1;
   }
   $h->delete;
   #print STDERR "$pos\n";
}

# Also try what happens when we feed the document one-char at a time
$h = undef;
while ($HTML =~ /(.)/sg) {
    $h = parse_html($1, $h);
}
$new_html = $h->as_HTML;
if ($new_html ne $html) {
   print "Also different when parsed one char at a time\n";
   print "\n$html$new_html\n";
   $BAD = 1;
}

print "not " if $BAD;
print "ok 2\n";