package AFM;

# This package is a simple parser for Adobe Font Metrics files.
#
# $Id: AFM.pm,v 1.3 1995/05/14 13:56:04 aas Exp $
#
# Author: Gisle Aas <aas@oslonett.no>

use Carp;

# The metrics_path is used to locate metrics files
#
$metrics_path = $ENV{METRICS} || "/usr/openwin/lib/fonts/afm/:.";
@metrics_path = split(/:/, $metrics_path);
foreach (@metrics_path) { s,/$,, }    # reove trailing slashes

@ISOLatin1Encoding = qw(
 .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
 .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
 .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
 .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef space
 exclam quotedbl numbersign dollar percent ampersand quoteright
 parenleft parenright asterisk plus comma minus period slash zero one
 two three four five six seven eight nine colon semicolon less equal
 greater question at A B C D E F G H I J K L M N O P Q R S
 T U V W X Y Z bracketleft backslash bracketright asciicircum
 underscore quoteleft a b c d e f g h i j k l m n o p q r s
 t u v w x y z braceleft bar braceright asciitilde .notdef .notdef
 .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
 .notdef .notdef .notdef .notdef .notdef .notdef .notdef dotlessi grave
 acute circumflex tilde macron breve dotaccent dieresis .notdef ring
 cedilla .notdef hungarumlaut ogonek caron space exclamdown cent
 sterling currency yen brokenbar section dieresis copyright ordfeminine
 guillemotleft logicalnot hyphen registered macron degree plusminus
 twosuperior threesuperior acute mu paragraph periodcentered cedilla
 onesuperior ordmasculine guillemotright onequarter onehalf threequarters
 questiondown Agrave Aacute Acircumflex Atilde Adieresis Aring AE
 Ccedilla Egrave Eacute Ecircumflex Edieresis Igrave Iacute Icircumflex
 Idieresis Eth Ntilde Ograve Oacute Ocircumflex Otilde Odieresis
 multiply Oslash Ugrave Uacute Ucircumflex Udieresis Yacute Thorn
 germandbls agrave aacute acircumflex atilde adieresis aring ae
 ccedilla egrave eacute ecircumflex edieresis igrave iacute icircumflex
 idieresis eth ntilde ograve oacute ocircumflex otilde odieresis divide
 oslash ugrave uacute ucircumflex udieresis yacute thorn ydieresis
);


# Creates a new AFM object.  Pass it the name of the font as parameter.
# Synopisis:
#
#    $h = new AFM "Helvetica";
#

sub new
{
   my($class, $fontname) = @_;
   $fontname =~ s/.amf$//;
   my $file = "$fontname.afm";
   unless ($file =~ m,^/,) {
       # not absolute, search the metrics path for the file
       foreach (@metrics_path) {
	   if (-f "$_/$file") {
	       $file = "$_/$file";
	       last;
	   }
       }
   }
   open(AFM, $file) or croak "Can't find the AFM file for $fontname";
   my $this = bless { };
   while (<AFM>) {
       next if /^StartKernData/ .. /^EndKernData/;  # kern data not parsed yet
       next if /^StartComposites/ .. /^EndComposites/; # same for composites
       if (/^StartCharMetrics/ .. /^EndCharMetrics/) {
	   next unless /^C\s/;
	   my($name) = /\bN\s+(\w+)\s*;/;
	   my($wx)   = /\bWX\s+(\d+)\s*;/;
	   my($bbox)    = /\bB\s+([^;]+)\s*;/;
	   $this->{'wx'}{$name} = $wx;
	   $this->{'bbox'}{$name} = $bbox;
	   next;
       }
       last if /^EndFontMetrics/;
       if (/(^\w+)\s+(.*)/) {
	   my($key,$val) = ($1, $2);
	   $key = lc $key;
	   if (defined $this->{$key}) {
	       $this->{$key} = [ $this->{$key} ] unless ref $this->{$key};
	       push(@{$this->{$key}}, $val);
	   } else {
	       $this->{$key} = $val;
	   }
       } else {
	   print STDERR "Can't parse: $_";
       }
   }
   close(AFM);
   $this->{wx}->{'.notdef'} = 0;
   $this->{bbox}{'.notdef'} = "0 0 0 0";
   $this;
}

# Returns an 256 element array that maps from characters to width
sub latin1_wx_table
{
    my($this) = @_;
    unless ($this->{'_wx_table'}) {
	$this->{'_wx_table'} =
	    [ map {$this->{wx}->{$ISOLatin1Encoding[$_]}} 0..255 ];
    }
    @{ $this->{'_wx_table'} };
}

sub stringwidth
{
    my($this, $string, $pointsize) = @_;
    my @wx = $this->latin1_wx_table;
    my $width = 0.0;
    while ($string =~ /./g) {
	$width += $wx[ord $&];
    }
    $width;
}

sub FontName;
sub FullName;
sub FamilyName;
sub Weight;
sub ItalicAngle;
sub IsFixedPitch;
sub FontBBox;
sub UnderlinePosition;
sub UnderlineThickness;
sub Version;
sub Notice;
sub Comment;
sub EncodingScheme;
sub CapHeight;
sub XHeight;
sub Descender;
sub Wx;
sub BBox;

sub AUTOLOAD
{
    #print "AUTOLOAD: $AUTOLOAD\n";
    if ($AUTOLOAD =~ /::DESTROY$/) {
	eval "sub $AUTOLOAD {}";
	goto &$AUTOLOAD;
    } else {
	my $name = $AUTOLOAD;
	$name =~ s/^.*:://;
	croak "Attribute $name not defined for AFM object"
	    unless defined $_[0]->{lc $name};
	return $_[0]->{lc $name};
    }
}


# Dumping might be usefull for debugging

sub dump
{
    my($this) = @_;
    my($key, $val);
    foreach $key (sort keys %$this) {
	if (ref $this->{$key}) {
	    if (ref $this->{$key} eq "ARRAY") {
		print "$key = [\n\t", join("\n\t", @{$this->{$key}}), "\n]\n";
	    } elsif (ref $this->{$key} eq "HASH") {
		print "$key = {\n";
		my $key2;
		foreach $key2 (sort keys %{$this->{$key}}) {
		    print "\t$key2 => $this->{$key}{$key2},\n";
		}
		print "}\n";
	    } else {
		print "$key = $this->{$key}\n";
	    }
	} else {
	    print "$key = $this->{$key}\n";
	}
    }
}

1;
