print "1..1\n";

require Font::AFM;

eval {
   $font = new Font::AFM "Helvetica";
};
if ($@) {
   if ($@ =~ /Can't find the AFM file for/) {
	print "ok 1\n";  # we just don't care to make this fail so easy
   } else {
        print $@;
        print "not ok 1\n";
   }
   exit;
}

$sw = $font->stringwidth("Gisle Aas");

if ($sw == 4279) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
    print "The stringwidth of 'Gisle Aas' should be 4279 (is was $sw)\n";
}

