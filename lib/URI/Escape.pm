#
# $Id: Escape.pm,v 3.3 1996/01/05 12:55:49 aas Exp $
#

package URI::Escape;

=head1 NAME

uri_escape - Escape unsafe characters

uri_unescape - Unescape escaped characters

=head1 SYNOPSIS

 use URI::Escape;
 $safe = uri_escape("10% is enough\n");
 $str  = uri_unescape($safe);

=head1 DESCRIPTION

This module provide functions to escape and unescape URIs strings.
Some characters are regarded as "unsafe" and must be escaped in
accordance with RFC 1738.  Escaped characters are represented by a
triplet consisting of the character "%" followed by two hexadecimal
digits.

The uri_escape() function takes an optional second argument that
overrides the set of characters that are to be escaped.

=head1 SEE ALSO

L<URI::URL>

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(uri_escape uri_unescape);
@EXPORT_OK = qw(%escapes);

# Build a char->hex map
for (0..255) {
    $escapes{chr($_)} = sprintf("%%%02X", $_);
}

sub uri_escape
{
    my($text, $patn) = @_;
    if (defined $patn){
	unless (exists  $subst{$patn}) {
	    # Because we can't compile regex we fake it with a cached sub
	    $subst{$patn} =
	      eval "sub {\$_[0] =~ s/([$patn])/\$escapes{\$1}/g; }";
	    die $@ if $@;
	}
	&{$subst{$patn}}($text);
	return $text;
    }
    # Default unsafe characters. (RFC1738 section 2.2)
    $text =~ s/([\x00-\x20"#%;<>?{}|\\\\^~`\[\]\x7F-\xFF])/$escapes{$1}/g; #"
    $text;
}

sub uri_unescape
{
    my($text) = @_;
    return undef unless defined $text;
    # Note from RFC1630:  "Sequences which start with a percent sign
    # but are not followed by two hexadecimal characters are reserved
    # for future extension"
    $text =~ s/%([\dA-Fa-f][\dA-Fa-f])/chr(hex($1))/eg;
    $text;
}

1;
