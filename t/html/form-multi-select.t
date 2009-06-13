#!/usr/bin/perl

# Test for case when multiple forms are on a page with same-named <select> fields. 

use strict;
use Test::More tests => 2;
use HTML::Form;

{ 
    my $test = "the settings of a previous form should not interfere with a latter form (control test with one form)";
    my @forms = HTML::Form->parse( FakeResponse::One->new );
    my $cat_form = $forms[0];
    my @vals = $cat_form->param('age');
    is_deeply(\@vals,[''], $test);
}
{ 
    my $test = "the settings of a previous form should not interfere with a latter form (test with two forms)";
    my @forms = HTML::Form->parse( FakeResponse::TwoForms->new );
    my $cat_form = $forms[1];

    my @vals = $cat_form->param('age');
    is_deeply(\@vals,[''], $test);
}

####
package FakeResponse::One;
sub new {
    bless {}, shift;
}
sub base {
    return "http://foo.com"
}
sub content_charset {
    return "iso-8859-1";
}
sub decoded_content {
    my $html = qq{
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <title></title>
    </head>
    <body>

    <form name="search_cats">
    <select name="age" onChange="jumpTo(this)" class="sap-form-item">
    <option value="" selected="selected">Any</option>
    <option value="young">Young</option>
    <option value="adult">Adult</option>
    <option value="senior">Senior</option>
    <option value="puppy">Puppy </option>
    </select>
    </form>
    </body></html>
    };
    return \$html;
}

#####
package FakeResponse::TwoForms;
sub new {
    bless {}, shift;
}
sub base {
    return "http://foo.com"
}
sub decoded_content {
    my $html = qq{
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <title></title>
    </head>
    <body>
    <form name="search_dogs" >
    <select name="age" onChange="jumpTo(this)" class="sap-form-item">
    <option value="" selected="selected">Any</option>
    <option value="young">Young</option>
    <option value="adult">Adult</option>
    <option value="senior">Senior</option>
    <option value="puppy">Puppy </option>
    </select>
    </form>


    <form name="search_cats">
    <select name="age" onChange="jumpTo(this)" class="sap-form-item">
    <option value="" selected="selected">Any</option>
    <option value="young">Young</option>
    <option value="adult">Adult</option>
    <option value="senior">Senior</option>
    <option value="puppy">Puppy </option>
    </select>
    </form>
    </body></html>
    };
    return \$html;
}
