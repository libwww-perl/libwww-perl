#
# $Id: MediaTypes.pm,v 1.5 1995/08/09 09:54:15 aas Exp $

package LWP::MediaTypes;

=head1 NAME

LWP::MediaTypes - Library for media types

=head1 DESCRIPTION

This module is supposed to handle mailcap files so that we are able to
determine media (also known as MIME) types for files and URLs.
Currently it does not do much.

=head1 TO DO

=over 3 

=item * 

Read mailcap

=item *

Read types from server config files.

=item *

Guess types for non http:-URLs.

=back

=cut

####################################################################

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(guessMediaType);

my %types = (
   'txt'  => 'text/plain',
   'html' => 'text/html',
   'htm'  => 'text/html',
   'gif'  => 'image/gif',
   'jpg'  => 'image/jpeg',
   'jfif' => 'image/jpeg',
   'au'   => 'audio/basic',
   'mpg'  => 'video/mpeg',
   'qt'   => 'video/quicktime',
);

my %encoding = (
   'gz'   => 'x-gzip',
   'z'    => 'x-compress',
   'uu'   => 'x-uuencode',
   'hqx'  => 'x-hqx',
);


####################################################################

=head1 FUNCTIONS

=head2 guessMediaType($filename)

Guess media type for given file.

This is OK to use to implement the file:// URL
scheme under UNIX. It should not be used to
guess media types from URLs.

=cut

sub guessMediaType
{
    my($file) = @_;
    my($ext);
    ($ext = $file) =~ s/.*\.(.*)/\L$1/;
    return $types{$ext};
}
    

1;
