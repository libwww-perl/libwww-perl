use HTML::Entities qw(decode_entities encode_entities);

print "1..4\n";

$a = "V&aring;re norske tegn b&oslash;r &#230res";

decode_entities($a);

print "ok 1\n" if $a eq "Våre norske tegn bør æres";

encode_entities($a);

print "ok 2\n" if $a eq "V&aring;re norske tegn b&oslash;r &aelig;res";

$a = "<&>";
print "ok 3\n" if encode_entities($a) eq "&lt;&amp;&gt;";

$a = "abcdef";
print "ok 4\n" if encode_entities($a, 'a-c') eq "&#97;&#98;&#99;def";
