#!perl

use strict;
use warnings;
use Test qw(plan ok);

plan tests => 2;

use HTML::Form;

{
my $form = HTML::Form->parse(<<"EOT", base => "http://example.com", strict => 1);
<form>
 <label>
   <input name="tt" type="text" value="test content">
 </label>
</form>
EOT
ok($form->param('tt'), 'test content');

}

{
my $form = HTML::Form->parse(<<"EOT", base => "http://example.com", strict => 1);
<form>
 <label>
   <textarea name="tt">test content</textarea>
 </label>
</form>
EOT

ok($form->param('tt'), 'test content');
}
