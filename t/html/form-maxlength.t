#!/usr/bin/perl

use strict;
use warnings;
use lib '.';
use Test::More tests => 12;
use HTML::Form;

my $html = do { local $/ = undef; <DATA> };
my $form = HTML::Form->parse($html, 'foo.html' );
isa_ok($form, 'HTML::Form');
my $input = $form->find_input('passwd');
isa_ok($input, 'HTML::Form::TextInput');

sub set_value {
  my $input = shift;
  my $value = shift;
  my $len = length($value);
  my $old = $input->value;
  is( $input->value($value), $old, "set value length=$len" );
  is( $input->value, $value, "got value length=$len" );
}

{
  is( $input->{maxlength}, 8, 'got maxlength: 8' );

  set_value( $input, '1234' );
  set_value( $input, '1234567890' );
  ok(!$input->strict, "not strict by default");
  $form->strict(1);
  ok($input->strict, "input strict change when form strict change");
  set_value( $input, '1234' );
  eval {
      set_value( $input, '1234567890' );
  };
  like($@, qr/^Input 'passwd' has maxlength '8' at /, "Exception raised");
}

__DATA__

<form method="post" action="?" enctype="application/x-www-form-urlencoded" name="login">
<div style="display:none"><input type="hidden" name="node_id" value="109"></div>
<input type="hidden" name="op" value="login" />
<input type="hidden" name="lastnode_id" value="109" />
<table border="0"><tr><td><font size="2">
Login:</font></td><td>
<input type="text" name="user"  size=10 maxlength=34 />
</td></tr><tr><td><font size="2">
Password</font></td><td>
<input type="password" name="passwd"  size=10 MAXLENGTH=8 />

</td></tr></table><font size="2">
<input type="checkbox" name="expires" value="+10y" />remember me
<input type="submit" name="login" value="Login" />
</font><br />
<a href="?node=What%27s%20my%20password%3F">password reminder</a>
<br />
<a href="?node_id=101">Create A New User</a>
</form>

