package HTML::Entities;

# $Id: Entities.pm,v 1.4 1996/05/08 16:32:10 aas Exp $

=head1 NAME

decode - Expand HTML entites in a string

encode - Encode chars in a string using HTML entities

=head1 SYNOPSIS

 use HTML::Entities;

 $a = "V&aring;re norske tegn b&oslash;r &#230res";
 decode_entities($a);
 encode_entities($a, "\200-\377");

=head1 DESCRIPTION

The decode_entities() routine replace valid HTML entities found
in the string with the corresponding character.

The encode_entities() routine replace the characters specified by the
second argument with their entity representation.  The default set of
characters to expand are control chars, high-bit chars and the '<',
'&', '>' and '"' character.

Both routines modify the string passed in as the first argument and
return it.

If you prefer not to import these routines into your namespace you can
call them as:

  require HTML::Entities;;
  $encoded = HTML::Entities::encode($a);
  $decoded = HTML::Entities::decode($a);

The module can also export the %char2entity and the %entity2char
hashes which contains the mapping from all characters to the
corresponding entities.

=head1 COPYRIGHT

Copyright 1995, 1996 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@a.sn.no>

=cut


require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(encode_entities decode_entities);
@EXPORT_OK = qw(%entity2char %char2entity);

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);
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


sub decode_entities
{
    for (@_) {
	s/(&\#(\d+);?)/$2 < 256 ? chr($2) : $1/eg;
	s/(&(\w+);?)/$entity2char{$2} || $1/eg;
    }
    $_[0];
}

sub encode_entities
{
    if (defined $_[1]) {
	unless (exists $subst{$_[1]}) {
	    # Because we can't compile regex we fake it with a cached sub
	    $subst{$_[1]} =
	      eval "sub {\$_[0] =~ s/([$_[1]])/\$char2entity{\$1}/g; }";
	    die $@ if $@;
	}
	&{$subst{$_[1]}}($_[0]);
    } else {
	# Encode control chars, high bit chars and '<', '&', '>', '"'
	$_[0] =~ s/([^\n\t !#$%'-;=?-~])/$char2entity{$1}/g;
    }
    $_[0];
}

# Set up aliases
*encode = \&encode_entities;
*decode = \&decode_entities;

1;
