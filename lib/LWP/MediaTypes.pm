#
# $Id: MediaTypes.pm,v 1.7 1995/08/21 13:25:00 aas Exp $

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


# Try to locate "mime.types" file, and initialize %suffixType from it
for $typefile ("$ENV{HOME}/.mime.types", map {"$_/LWP/mime.types"} @INC) {
    if (open(TYPE, "$typefile")) {
	%suffixType = ();  # forget default types
	while (<TYPE>) {
	    next if /^\s*#/; # comment line
	    next if /^\s*$/; # blank line
	    my($type, @exts) = split(' ', $_);
	    for $ext (@exts) {
		$suffixType{$ext} = $type;
	    }
	}
	close(TYPE);
	last;
    }
}


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


=head2 mediaSuffix($type)

  mediaSuffix('image/*')

This function will return all suffixes that are used to denote the
specified media type.  Wildcard types can be used.

=cut

sub mediaSuffix {
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
