#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 12;

use HTML::Form;

my $form = HTML::Form->parse(<<"EOT", base => "http://example.com", strict => 1);
<form>
<input name="n1" id="id1" class="A" value="1">
<input id="id2" class="A" value="2">
<input id="id3" class="B" value="3"> 
<select id="id4">
   <option>1
   <option>2
   <option>3
</selector>
<input id="#foo" name="#bar" class=".D" disabled>
</form>
EOT

#$form->dump;

ok($form->value("n1"), 1);
ok($form->value("^n1"), 1);
ok($form->value("#id1"), 1);
ok($form->value(".A"), 1);
ok($form->value("#id2"), 2);
ok($form->value(".B"), 3);

ok(j(map $_->value, $form->find_input(".A")), "1:2");

$form->find_input("#id2")->name("n2");
$form->value("#id2", 22);
ok($form->click->uri->query, "n1=1&n2=22");

# try some odd names
ok($form->find_input("##foo")->name, "#bar");
ok($form->find_input("#bar"), undef);
ok($form->find_input("^#bar")->class, ".D");
ok($form->find_input("..D")->id, "#foo");

sub j {
    join(":", @_);
}
