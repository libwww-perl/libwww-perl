#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 52;

use HTML::Form;

my @warn;
$SIG{__WARN__} = sub { push(@warn, $_[0]) };

my @f = HTML::Form->parse("", "http://localhost/");
ok(@f, 0);

@f = HTML::Form->parse(<<'EOT', "http://localhost/");
<form action="abc" name="foo">
<input name="name">
</form>
<form></form>
EOT

ok(@f, 2);

my $f = shift @f;
ok($f->value("name"), "");
ok($f->dump, "GET http://localhost/abc [foo]\n  name=\n");

my $req = $f->click;
ok($req->method, "GET");
ok($req->uri, "http://localhost/abc?name=");

$f->value(name => "Gisle Aas");
$req = $f->click;
ok($req->method, "GET");
ok($req->uri, "http://localhost/abc?name=Gisle+Aas");

ok($f->attr("name"), "foo");
ok($f->attr("method"), undef);

$f = shift @f;
ok($f->method, "GET");
ok($f->action, "http://localhost/");
ok($f->enctype, "application/x-www-form-urlencoded");
ok($f->dump, "GET http://localhost/\n");

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

ok($f->click->as_string, <<'EOT');
POST http://localhost/
Content-Length: 76
Content-Type: application/x-www-form-urlencoded

i.x=1&i.y=1&c=on&r=b&t=&p=&h=xyzzy&f=foo.txt&x=&a=%0Aabc%0A+++&s=bar&m=a&m=b
EOT

ok(@warn, 1);
ok($warn[0] =~ /^Unknown input type 'xyzzy'/);
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

ok($f->click->as_string, <<'EOT');
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

ok($f->click->as_string, <<"EOT");
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

ok(@warn, 0);

# Try to parse form HTTP::Response directly
{
    package MyResponse;
    use vars qw(@ISA);
    require HTTP::Response;
    @ISA = ('HTTP::Response');

    sub base { "http://www.example.com" }
}
my $response = MyResponse->new(200, 'OK');
$response->content("<form><input type=text value=42 name=x></form>");

$f = HTML::Form->parse($response);

ok($f->click->as_string, <<"EOT");
GET http://www.example.com?x=42

EOT

$f = HTML::Form->parse(<<EOT, "http://www.example.com");
<form>
   <input type=checkbox name=x> I like it!
</form>
EOT

$f->find_input("x")->check;

ok($f->click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT

$f->value("x", "off");
ok($f->click->as_string, <<"EOT");
GET http://www.example.com

EOT

$f->value("x", "I like it!");
ok($f->click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT

$f->value("x", "I LIKE IT!");
ok($f->click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT

$f = HTML::Form->parse(<<EOT, "http://www.example.com");
<form>
<select name=x>
   <option value=1>one
   <option value=2>two
   <option>3
</select>
<select name=y multiple>
   <option value=1>
</select>
</form>
EOT

$f->value("x", "one");

ok($f->click->as_string, <<"EOT");
GET http://www.example.com?x=1

EOT

$f->value("x", "TWO");
ok($f->click->as_string, <<"EOT");
GET http://www.example.com?x=2

EOT

ok(join(":", $f->find_input("x")->value_names), "one:two:3");
ok(join(":", map $_->name, $f->find_input(undef, "option")), "x:y");

$f = HTML::Form->parse(<<EOT, "http://www.example.com");
<form>
<input name=x value=1 disabled>
<input name=y value=2 READONLY type=TEXT>
<input name=z value=3 type=hidden>
</form>
EOT

ok($f->value("x"), 1);
ok($f->value("y"), 2);
ok($f->value("z"), 3);
ok($f->click->uri->query, "y=2&z=3");

my $input = $f->find_input("x");
ok($input->type, "text");
ok(!$input->readonly);
ok($input->disabled);
ok($input->disabled(0));
ok(!$input->disabled);
ok($f->click->uri->query, "x=1&y=2&z=3");

$input = $f->find_input("y");
ok($input->type, "text");
ok($input->readonly);
ok(!$input->disabled);

$input->value(22);
ok($f->click->uri->query, "x=1&y=22&z=3");
ok(@warn, 1);
ok($warn[0] =~ /^Input 'y' is readonly/);
@warn = ();

ok($input->readonly(0));
ok(!$input->readonly);

$input->value(222);
ok(@warn, 0);
print @warn;
ok($f->click->uri->query, "x=1&y=222&z=3");

$input = $f->find_input("z");
ok($input->type, "hidden");
ok($input->readonly);
ok(!$input->disabled);
