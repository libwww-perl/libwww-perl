use HTML::Parse;
require HTML::FormatText;

sub test_it {
    $html = parse_html(shift);
    $formatter = new HTML::FormatText;
    print $formatter->format($html);
}

&test_it('
<P>This first paragraph will be indented by an extra space
because the leading newline in the HTML source is not stripped.</P>

<P>Next, we will try some fixed-width text.  Testing:
<TT>test test test test</TT>.  Note how the line is broken
between the last "test" and the period following it.
</P>

<P>There is an awfully large amount of vertical space between the
paragraphs.  A single empty line would be enough.</P>

<P>The right margin setting is apparently treated as a minimum line length,
not a maximum like I would have expected.  This means that if some
much-longer-than-usual word happens to fall at the end of
the line, it will stick out like a sore thumb.</P>

<UL>
<LI>The first item in an unnumbered list gets the asterisk wrong.
<LI>Subsequent items are fine,
<LI>as you can see.
</UL>
');
