
print "1..2\n";

$HTML = <<'EOT';

<title>&Aring være eller &#229; ikke være</title>
<meta http-equiv="Expires" content="Soon">
<meta http-equiv="Foo" content="Bar">
<link href="mailto:aas@sn.no" rev=made title="Gisle Aas">

<script>

    ignore this

</script>

<base href="http://www.sn.no">

Dette er også vanlig tekst

<style>

   ignore this too

</style>

<isindex>

Dette er vanlig tekst.


EOT

$| = 1;

#$HTML::HeadParser::DEBUG = 1;
require HTML::HeadParser;
$p = new HTML::HeadParser;

$bad = 0;

print "\n#### Parsing full text...\n";
if ($p->parse($HTML)) {
    $bad++;
    print "Need more data which should not happen\n";
} else {
    print $p->as_string;
}

$p->header('Title') =~ /Å være eller å ikke være/ or $bad++;
$p->header('Expires') eq 'Soon' or $bad++;
$p->header('Content-Base') eq 'http://www.sn.no' or $bad++;
$p->header('Link') =~ /<mailto:aas\@sn.no>/ or $bad++;

# This header should not be present because the head ended
$p->header('Isindex') and $bad++;

print "not " if $bad;
print "ok 1\n";


# Try feeding one char at a time
print "\n\n#### Parsing once char at a time...\n";
$expected = $p->as_string;
$p = new HTML::HeadParser;
while ($HTML =~ /(.)/sg) {
    print $1;
    $p->parse($1) or last;
}
print "«««« Enough!!\n";
$got = $p->as_string;
print "$got";
print "not " if $expected ne $got;
print "ok 2\n";
