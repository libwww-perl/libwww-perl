#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 22;

use HTML::Form;

my $form = HTML::Form->parse(<<"EOT", base => "http://example.com", strict => 1);
<form>
<input type="hidden" name="hidden_1">

<input type="checkbox" name="checkbox_1" value="c1_v1" CHECKED>
<input type="checkbox" name="checkbox_1" value="c1_v2" CHECKED>
<input type="checkbox" name="checkbox_2" value="c2_v1" CHECKED>

<select name="multi_select_field" multiple="1">
 <option> 1
 <option> 2
 <option> 3
</select>
</form>
EOT

# list names
ok($form->param, 4);
ok(j($form->param), "hidden_1:checkbox_1:checkbox_2:multi_select_field");

# get
ok($form->param('hidden_1'), '');
ok($form->param('checkbox_1'), 'c1_v1');
ok(j($form->param('checkbox_1')), 'c1_v1:c1_v2');
ok($form->param('checkbox_2'), 'c2_v1');
ok(j($form->param('checkbox_2')), 'c2_v1');
ok(!defined($form->param('multi_select_field')));
ok(j($form->param('multi_select_field')), '');
ok(!defined($form->param('unknown')));
ok(j($form->param('unknown')), '');

# set
eval {
    $form->param('hidden_1', 'x');
};
ok($@, qr/readonly/);
ok(j($form->param('hidden_1')), '');

eval {
    $form->param('checkbox_1', 'foo');
};
ok($@, qr/Illegal value/);
ok(j($form->param('checkbox_1')), 'c1_v1:c1_v2');

$form->param('checkbox_1', 'c1_v2');
ok(j($form->param('checkbox_1')), 'c1_v2');
$form->param('checkbox_1', 'c1_v2');
ok(j($form->param('checkbox_1')), 'c1_v2');
$form->param('checkbox_1', []);
ok(j($form->param('checkbox_1')), '');
$form->param('checkbox_1', ['c1_v2', 'c1_v1']);
ok(j($form->param('checkbox_1')), 'c1_v1:c1_v2');
$form->param('checkbox_1', []);
ok(j($form->param('checkbox_1')), '');
$form->param('checkbox_1', 'c1_v2', 'c1_v1');
ok(j($form->param('checkbox_1')), 'c1_v1:c1_v2');

$form->param('multi_select_field', 3, 2);
ok(j($form->param('multi_select_field')), "2:3");

sub j {
    join(":", @_);
}
