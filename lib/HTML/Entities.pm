package HTML::Entities;

# $Id: Entities.pm,v 1.1 1995/09/05 23:03:51 aas Exp $

=head1 NAME

decode - Expand HTML entites in a string

encode - Encode chars in a string using HTML entities

=head1 SYNOPSIS

 require HTML::Entities;

 $a = "V&aring;re norske tegn b&oslash;r &#230res";
 HTML::Entities::decode($a);
 HTML::Entities::encode($a, "\200-\377");

=head1 DESCRIPTION

The HTML::Entities::decode() routine replace valid HTML entities found
in the string with the corresponding character.  The
HTML::Entities::encode() routine replace the characters specified by the
second argument with their entity representation.  The default set of
characters to expand are control chars, high bit chars and '<', '&', '>'
and '"'.

Both routines modify the string and return it.

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut


require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(encode decode);

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }


%entity2char = (

 'lt'     => '<',
 'gt'     => '>',
 'amp'    => '&',
 'quot'   => '"',
 'nbsp'   => "\240",

 'Aacute' => 'Á',
 'Acirc'  => 'Â',
 'Agrave' => 'À',
 'Aring'  => 'Å',
 'Atilde' => 'Ã',
 'Auml'   => 'Ä',
 'Ccedil' => 'Ç',
 'ETH'    => 'Ð',
 'Eacute' => 'É',
 'Ecirc'  => 'Ê',
 'Egrave' => 'È',
 'Euml'   => 'Ë',
 'Iacute' => 'Í',
 'Icirc'  => 'Î',
 'Igrave' => 'Ì',
 'Iuml'   => 'Ï',
 'Ntilde' => 'Ñ',
 'AElig'  => 'Æ',
 'Oacute' => 'Ó',
 'Ocirc'  => 'Ô',
 'Ograve' => 'Ò',
 'Oslash' => 'Ø',
 'Otilde' => 'Õ',
 'Ouml'   => 'Ö',
 'THORN'  => 'Þ',
 'Uacute' => 'Ú',
 'Ucirc'  => 'Û',
 'Ugrave' => 'Ù',
 'Uuml'   => 'Ü',
 'Yacute' => 'Ý',
 'aelig'  => 'æ',
 'aacute' => 'á',
 'acirc'  => 'â',
 'agrave' => 'à',
 'aring'  => 'å',
 'atilde' => 'ã',
 'auml'   => 'ä',
 'ccedil' => 'ç',
 'eacute' => 'é',
 'ecirc'  => 'ê',
 'egrave' => 'è',
 'eth'    => 'ð',
 'euml'   => 'ë',
 'iacute' => 'í',
 'icirc'  => 'î',
 'igrave' => 'ì',
 'iuml'   => 'ï',
 'ntilde' => 'ñ',
 'oacute' => 'ó',
 'ocirc'  => 'ô',
 'ograve' => 'ò',
 'oslash' => 'ø',
 'otilde' => 'õ',
 'ouml'   => 'ö',
 'szlig'  => 'ß',
 'thorn'  => 'þ',
 'uacute' => 'ú',
 'ucirc'  => 'û',
 'ugrave' => 'ù',
 'uuml'   => 'ü',
 'yacute' => 'ý',
 'yuml'   => 'ÿ',

 # Netscape extentions
 'reg'    => '®',
 'copy'   => '©',

);

# Make the oposite mapping
while (($entity, $char) = each(%entity2char)) {
    $char2entity{$char} = "&$entity;";
}

# Fill inn missing entities
for (0 .. 255) {
    next if exists $char2entity{chr($_)};
    $char2entity{chr($_)} = "&#$_;";
}


sub decode
{
    for (@_) {
	s/(&\#(\d+);?)/$2 < 256 ? chr($2) : $1/eg;
	s/(&(\w+);?)/$entity2char{$2} || $1/eg;
    }
    $_[0];
}

sub encode
{
    if (defined $_[1]) {
	$_[0] =~ s/([$_[1]])/$char2entity{$1}/g;
    } else {
	# Encode control chars, high bit chars and '<', '&', '>', '"'
	$_[0] =~ s/([^\n\t !#$%'-;=?-~])/$char2entity{$1}/g;
    }
    $_[0];
}

1;
