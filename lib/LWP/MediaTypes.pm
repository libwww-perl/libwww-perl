#
# $Id: MediaTypes.pm,v 1.14 1996/05/08 16:28:55 aas Exp $

package LWP::MediaTypes;

=head1 NAME

guess_media_type - guess media type for a file or a URL.

media_suffix - returns file extentions for a media type

=head1 DESCRIPTION

This module provides functions for handling of media (also known as
MIME) types and encodings.  The mapping from file extentions to media
types is defined by the F<media.types> file.  If the F<~/.media.types>
file exist it is used as a replacement.

For backwards compatability we will also look for F<~/.mime.types>.

=cut

####################################################################

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(guess_media_type media_suffix);

require LWP::Debug;

my %suffixType = (              # note: initialized from mime.types
    'txt'   => 'text/plain',
    'html'  => 'text/html',
    'gif'   => 'image/gif',
    'jpg'   => 'image/jpeg',
);

my %suffixEncoding = (
    'Z'   => 'compress',
    'gz'  => 'gzip',
    'hqx' => 'x-hqx',
    'uu'  => 'x-uuencode',
    'z'   => 'x-pack'
);

local($/, $_) = ("\n", undef);  # ensure correct $INPUT_RECORD_SEPARATOR

# Try to locate "media.types" file, and initialize %suffixType from it
for $typefile ((map {"$_/LWP/media.types"} @INC),
	       "$ENV{HOME}/.media.types",
	       "$ENV{HOME}/.mime.types",
	       ) {
    open(TYPE, $typefile) || next;
    LWP::Debug::debug("Reading media types from $typefile");
    while (<TYPE>) {
	next if /^\s*#/; # comment line
	next if /^\s*$/; # blank line
	s/#.*//;         # remove end-of-line comments
	my($type, @exts) = split(' ', $_);
	for $ext (@exts) {
	    $suffixType{$ext} = $type;
	}
    }
    close(TYPE);
}


####################################################################

=head1 FUNCTIONS

=head2 guess_media_type($filename)

This function tries to guess media type and encoding for given file.
In scalar context it returns only the content-type.  In array context
it returns an array consisting of content-type followed by any
content-encodings applied.

The guess_media_type function also accepts a URI::URL object as argument.

If the type can not be deduced from looking at the file name only,
then guess_media_type() will take a look at the actual file using the
C<-T> perl operator in order to determine if this is a text file
(text/plain).  If this does not work it will return
I<application/octet-stream> as the type.

=cut

sub guess_media_type
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
	if (exists $suffixEncoding{$_}) {
	    unshift(@encoding, $suffixEncoding{$_});
	    next;
	}
	if (exists $suffixEncoding{lc $_}) {
	    unshift(@encoding, $suffixEncoding{lc $_});
	    next;
	}

	# check content-type
	if (exists $suffixType{$_}) {
	    $ct = $suffixType{$_};
	    last;
	}
	if (exists $suffixType{lc $_}) {
	    $ct = $suffixType{lc $_};
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


=head2 media_suffix($type)

  media_suffix('image/*')

This function will return all suffixes that can be used to denote the
specified media type.  Wildcard types can be used.

=cut

sub media_suffix {
    my(@type) = @_;
    my(@suffix,$nom,$val);
    foreach (@type) {
	s/\*/.*/;
	while(($nom,$val) = each(%suffixType)) {
	    push(@suffix, $nom) if $val =~ /^$_$/;
	}
    }
    @suffix;
}

1;
