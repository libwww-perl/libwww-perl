print "1..6\n";

use HTML::Form;

my @f = HTML::Form->parse("", "http://localhost");
print "not " if @f;
print "ok 1\n";

@f = HTML::Form->parse(<<'EOT', "http://localhost/");

<form action="abc" name="foo">

<input name="name" value="Gisle">

</form>

EOT

print "not " unless @f == 1;
print "ok 2\n";

my $f = shift @f;
print "not " unless $f->value("name") eq "Gisle";
print "ok 3\n";

$f->value(name => "Gisle Aas");
$req = $f->click;
print "not " unless $req && $req->method eq "GET"
	                 && $req->uri eq "http://localhost/abc?name=Gisle+Aas";
print "ok 4\n";

print "not " unless $f->attr("name") eq "foo";
print "ok 5\n";

print "not " if $f->attr("method");
print "ok 6\n";
