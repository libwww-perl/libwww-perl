#
# $Id: MediaTypes.pm,v 1.2 1995/07/11 13:20:58 aas Exp $

package LWP::MIMEtypes;

=head1 NAME

LWP::MIMEtypes - Library for MIME types

=head1 DESCRIPTION

Not yet.

=head1 TO DO

Read mailcap

Read types from server config files.

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

sub guessType {
    my($file) = @_;
    my($ext);
    ($ext = $file) =~ s/.*\.(.*)/\L$1/;
    return $types{$ext};
}
    

1;
