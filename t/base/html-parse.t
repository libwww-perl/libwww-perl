print "1..1\n";

use HTML::Parse;

$h = parse_html <<'EOT';

<Title>Test page
</title>

<h1>Header</h1>

This is a link to <a href="http://www.oslonett.no/">Oslonett AS</a>.

<!-- This is
a <strong>comment</strong>
    -->

<p>
<table>
<tr><td>gisle<td>aas
<tr><td>see
</table>

EOT

open(STDERR, '>&STDOUT');  # Redirect STDERR to STDOUT

print STDERR "\n";
$h->dump;

$html = $h->asHTML;

print "ok 1\n" if $html =~ /<BODY>/ && $html =~ /www\.oslonett\.no/
	       && $html !~ /comment/;

