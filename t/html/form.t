print "1..10\n";

use strict;
use HTML::Form;

my @f = HTML::Form->parse("", "http://localhost/");
print "not " if @f;
print "ok 1\n";

@f = HTML::Form->parse(<<'EOT', "http://localhost/");
<form action="abc" name="foo">
<input name="name">
</form>
<form></form>
EOT

print "not " unless @f == 2;
print "ok 2\n";

my $f = shift @f;
print "not " unless defined($f->value("name")) && $f->value("name") eq "";
print "ok 3\n";

my $req = $f->click;
print "not " unless $req &&
	            $req->method eq "GET" &&
	            $req->uri eq "http://localhost/abc?name=";
print "ok 4\n";

$f->value(name => "Gisle Aas");
$req = $f->click;
print "not " unless $req &&
	            $req->method eq "GET" &&
	            $req->uri eq "http://localhost/abc?name=Gisle+Aas";
print "ok 5\n";

print "not " unless $f->attr("name") eq "foo";
print "ok 6\n";

print "not " if $f->attr("method");
print "ok 7\n";

$f = shift @f;
print "not " unless $f->method eq "GET" &&
	            $f->action eq "http://localhost/" &&
	            $f->enctype eq "application/x-www-form-urlencoded";
print "ok 8\n";

print "not " unless $f->dump eq "GET http://localhost/\n";
print "ok 9\n";

# try some more advanced inputs
$f = HTML::Form->parse(<<'EOT', "http://localhost/");
<form method=post>
   <input name=i type="image" src="foo.gif">
   <input name=c type="checkbox" checked>
   <input name=r type="radio" value="a">
   <input name=r type="radio" value="b" checked>
   <input name=t type="text">
   <input name=p type="PASSWORD">
   <input name=h type="hidden" value=xyzzy>
   <input name=s type="submit" value="Doit!">
   <input name=r type="reset">
   <input name=b type="button">
   <input name=f type="file">
   <input name=x type="xyzzy">

   <textarea name=a>
abc
   </textarea>

   <select name=s>
      <option>Foo
      <option value="bar" selected>Bar
   </select>

   <select name=m multiple>
      <option selected value="a">Foo
      <option selected value="b">Bar
   </select>
</form>
EOT

print $f->dump;

print "not " unless $f->click->as_string eq <<'EOT'; print "ok 10\n";
POST http://localhost/
Content-Length: 66
Content-Type: application/x-www-form-urlencoded

i.x=1&i.y=1&c=on&r=b&t=&p=&h=xyzzy&f=&a=%0Aabc%0A+++&s=bar&m=a&m=b
EOT
