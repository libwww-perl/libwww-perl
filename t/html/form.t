#!perl -w

print "1..14\n";

use strict;
use HTML::Form;

my @warn;
$SIG{__WARN__} = sub { push(@warn, $_[0]) };

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
   <input name=f type="file" value="foo.txt">
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

#print $f->dump;
#print $f->click->as_string;

print "not " unless $f->click->as_string eq <<'EOT'; print "ok 10\n";
POST http://localhost/
Content-Length: 73
Content-Type: application/x-www-form-urlencoded

i.x=1&i.y=1&c=on&r=b&t=&p=&h=xyzzy&f=foo.txt&a=%0Aabc%0A+++&s=bar&m=a&m=b
EOT

print "not " unless @warn == 1 && $warn[0] =~ /^Unknown input type 'xyzzy'/;
print "ok 11\n";
@warn = ();


# test file upload
$f = HTML::Form->parse(<<'EOT', "http://localhost/");
<form method=post enctype="MULTIPART/FORM-DATA">
   <input name=f type=file value=>
   <input type=submit value="Upload it!">
</form>
EOT

#print $f->dump;
#print $f->click->as_string;

# XXX the parameter-less boundary in this case is clearly a bug.

print "not " unless $f->click->as_string eq <<'EOT'; print "ok 12\n";
POST http://localhost/
Content-Length: 0
Content-Type: multipart/form-data; boundary


EOT

my $filename = sprintf "foo-%08d.txt", $$;
die if -e $filename;

open(FILE, ">$filename") || die;
binmode(FILE);
print FILE "This is some text\n";
close(FILE) || die;

$f->value(f => $filename);

#print $f->click->as_string;

print "not " unless $f->click->as_string eq <<"EOT"; print "ok 13\n";
POST http://localhost/
Content-Length: 159
Content-Type: multipart/form-data; boundary=xYzZY

--xYzZY\r
Content-Disposition: form-data; name="f"; filename="$filename"\r
Content-Length: 18\r
Content-Type: text/plain\r
\r
This is some text
\r
--xYzZY--\r

EOT

unlink($filename) || warn "Can't unlink '$filename': $!";

print "not " if @warn;
print "ok 14\n";
