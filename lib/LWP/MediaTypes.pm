#
# $Id: MediaTypes.pm,v 1.4 1995/07/16 07:23:42 aas Exp $

package LWP::MIMEtypes;

=head1 NAME

LWP::MIMEtypes - Library for MIME types

=head1 DESCRIPTION

This module is supposed to handle mailcap files so that we are able to
determine MIME types for files and URLs.  Currently it does not no
much.

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
@EXPORT_OK = qw(guessType);

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

=head2 guessType($filename)

Guess MIME type for given file.

This is OK to use to implement the file:// URL
scheme under UNIX. It should not be used to
guess MIME types from URLs.

=cut

sub guessType
{
    my($file) = @_;
    my($ext);
    ($ext = $file) =~ s/.*\.(.*)/\L$1/;
    return $types{$ext};
}
    

1;
