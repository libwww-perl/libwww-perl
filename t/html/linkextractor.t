print "1..7\n";

require HTML::LinkExtor;

$HTML = <<HTML;
<head>
<base href="http://www.sn.no/">
</head>
<body background="http://www.sn.no/sn.gif">

This is <A HREF="link.html">link</a> and an <img SRC="img.jpg"
lowsrc="img.gif" alt="Image">.
HTML


# Try the callback interface
$links = "";
$p = HTML::LinkExtor->new(
  sub {
      my($tag, %links) = @_;
      print "$tag @{[%links]}\n";
      $links .= "$tag @{[%links]}\n";
  });

$p->parse($HTML); $p->parse(undef);

$links =~ m|^base href http://www\.sn\.no/$|m or print "not ";
print "ok 1\n";
$links =~ m|^body background http://www\.sn\.no/sn\.gif$|m or print "not ";
print "ok 2\n";
$links =~ m|^a href link\.html$|m or print "not ";
print "ok 3\n";

# Try with base URL and the $p->links interface.

$p = new HTML::LinkExtor undef, "http://www.sn.no/foo/foo.html";
$p->parse($HTML); $p->parse(undef);

@p = $p->links;
for (@p) {
    ($t, %attr) = @$_ if $_->[0] eq 'img';
    print "@$_\n";
}

$t eq 'img' || print "not ";
print "ok 4\n";

delete $attr{src} eq "http://www.sn.no/foo/img.jpg" || print "not ";
print "ok 5\n";

delete $attr{lowsrc} eq "http://www.sn.no/foo/img.gif" || print "not ";
print "ok 6\n";

scalar(keys %attr) && print "not "; # there should be no more attributes
print "ok 7\n";
