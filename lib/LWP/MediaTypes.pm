#
# $Id: MediaTypes.pm,v 1.6 1995/08/21 06:22:45 aas Exp $

package LWP::MediaTypes;

=head1 NAME

LWP::MediaTypes - Library for media types

=head1 DESCRIPTION

This module is supposed to handle mailcap files so that we are able to
determine media (also known as MIME) types for files and URLs.

Currently all behaviour is hard coded into this module.

=head1 TO DO

=over 3 

=item * 

Read mailcap

=item *

Read types from server config files.

=back

=cut

####################################################################

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(guessMediaType mediaSuffix);

my %types = (
    "mime"  => "www/mime",
    "bin"   => "application/octet-stream",
    "oda"   => "application/oda",
    "pdf"   => "application/pdf",
    "ps"    => "application/postscript",
    "eps"   => "application/postscript",
    "ai"    => "application/postscript",
    "rtf"   => "application/x-rtf",
    "csh"   => "application/x-csh",
    "dvi"   => "application/x-dvi",
    "hdf"   => "application/x-hdf",
    "latex" => "application/x-latex",
    "nc"    => "application/x-netcdf",
    "cdf"   => "application/x-netcdf",
    "sh"    => "application/x-sh",
    "tcl"   => "application/x-tcl",
    "tex"   => "application/x-tex",
    "texi"  => "application/x-texinfo",
    "texinfo" => "application/x-texinfo",
    "t"     => "application/x-troff",
    "roff"  => "application/x-troff",
    "tr"    => "application/x-troff",
    "man"   => "application/x-troff-man",
    "1"     => "application/x-troff-man",
    "2"     => "application/x-troff-man",
    "3"     => "application/x-troff-man",
    "4"     => "application/x-troff-man",
    "5"     => "application/x-troff-man",
    "6"     => "application/x-troff-man",
    "7"     => "application/x-troff-man",
    "8"     => "application/x-troff-man",
    "me"    => "application/x-troff-me",
    "ms"    => "application/x-troff-ms",
    "src"   => "application/x-wais-source",
    "bcpio" => "application/x-bcpio",
    "cpio"  => "application/x-cpio",
    "gtar"  => "application/x-gtar",
    "shar"  => "application/x-shar",
    "sv4cpio" => "application/x-sv4cpio",
    "igs"   => "application/iges",
    "iges"  => "application/iges",
    "stp"   => "application/STEP",
    "step"  => "application/STEP",
    "dxf"   => "application/dxf",
    "vda"   => "application/vda",
    "set"   => "application/set",
    "stl"   => "application/SLA",
    "dwg"   => "application/acad",
    "DWG"   => "application/acad",
    "SOL"   => "application/solids",
    "DRW"   => "application/drafting",
    "prt"   => "application/pro_eng",
    "unv"   => "application/i-deas",
    "CCAD"  => "application/clariscad",
    "snd"   => "audio/basic",
    "au"    => "audio/basic",
    "aiff"  => "audio/x-aiff",
    "aifc"  => "audio/x-aiff",
    "aif"   => "audio/x-aiff",
    "wav"   => "audio/x-wav",
    "gif"   => "image/gif",
    "ief"   => "image/ief",
    "jpg"   => "image/jpeg",
    "jpe"   => "image/jpeg",
    "jpeg"  => "image/jpeg",
    "jfif"  => "image/jpeg",
    "tif"   => "image/tiff",
    "tiff"  => "image/tiff",
    "ras"   => "image/cmu-raster",
    "pnm"   => "image/x-portable-anymap",
    "pbm"   => "image/x-portable-bitmap",
    "pgm"   => "image/x-portable-graymap",
    "ppm"   => "image/x-portable-pixmap",
    "rgb"   => "image/x-rgb",
    "xbm"   => "image/x-xbitmap",
    "xpm"   => "image/x-xpixmap",
    "xwd"   => "image/x-xwindowdump",
    "html"  => "text/html",
    "htm"   => "text/html",
    "htmls" => "text/html",
    "c"     => "text/plain",
    "h"     => "text/plain",
    "cc"    => "text/plain",
    "cxx"   => "text/plain",
    "hh"    => "text/plain",
    "m"     => "text/plain",
    "f90"   => "text/plain",
    "txt"   => "text/plain",
    "text"  => "text/plain",
    "pl"    => "text/plain",
    "pm"    => "text/plain",
    "rtx"   => "text/richtext",
    "tsv"   => "text/tab-separated-values",
    "etx"   => "text/x-setext",
    "mpg"   => "video/mpeg",
    "mpe"   => "video/mpeg",
    "mpeg"  => "video/mpeg",
    "qt"    => "video/quicktime",
    "mov"   => "video/quicktime",
    "avi"   => "video/x-msvideo",
    "movie" => "video/x-sgi-movie",
    "zip"   => "multipart/x-zip",
    "tar"   => "multipart/x-tar",
    "ustar" => "multipart/x-ustar",
);

my %encoding = (
    'Z'   => 'compress',
    'gz'  => 'gzip',
    'hqx' => 'x-hqx',
    'uu'  => 'x-uuencode',
    'z'   => 'x-pack'
);


####################################################################

=head1 FUNCTIONS

=head2 guessMediaType($filename)

This function tries to guess media type and encoding for given file.
In scalar context it returns only the content-type.  In array context
it returns an array consisting of content-type followed by any
content-encodings applied.

The guessMediaType function also accepts an URI::URL object as argument.

If the type can not be deduced from looking at the file name only,
then guessMediaType() will take a look at the actual file using the
C<-T> perl operator in order to determine if this is a text file
(text/plain).  If this does not work it will return
I<application/octet-stream> as the type.

=cut

sub guessMediaType
{
    my($file) = @_;
    return undef unless defined $file;

    my $fullname;
    if (ref($file)) {
	# assume URI::URL object
	$file = $file->path;
	#XXX should handle non http:, file: or ftp: URLs differently
    } else {
	$fullname = $file;  # enable peek at actual file
    }
    $file =~ s,.*/,,;   # only basename left
    my @parts = reverse split(/\./, $file);
    pop(@parts);        # never concider first part

    my @encoding = ();
    my $ct = undef;
    for (@parts) {
	# first check this dot part as encoding spec
	if (exists $encoding{$_}) {
	    unshift(@encoding, $encoding{$_});
	    next;
	}
	if (exists $encoding{lc $_}) {
	    unshift(@encoding, $encoding{lc $_});
	    next;
	}

	# check content-type
	if (exists $types{$_}) {
	    $ct = $types{$_};
	    last;
	}
	if (exists $types{lc $_}) {
	    $ct = $types{lc $_};
	    last;
	}

	# don't know nothing about this dot part, bail out
	last;
    }
    unless (defined $ct) {
	# Take a look at the file
	if (defined $fullname) {
	    $ct = (-T $fullname) ? "text/plain" : "application/octet-stream";
	} else {
	    $ct = "application/octet-stream";
	}
    }

    wantarray ? ($ct, @encoding) : $ct;
}


=head2 mediaSuffix($type)

  mediaSuffix('image/*')

This function will return all suffixes that are used to denote the
specified media type.  Wildcard types can be used.

=cut

sub mediaSuffix {
    my(@file) = @_;
    my(@suffix,$nom,$val);
    foreach (@file) {
	s/\*/.*/;
	while(($nom,$val) = each(%types)) {
	    push(@suffix, $nom) if $val =~ /^$_$/;
	}
    }
    @suffix;
}

1;
