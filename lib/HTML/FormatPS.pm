package HTML::FormatPS;

require HTML::Formatter;
use Carp;

@ISA = qw(HTML::Formatter);

sub mm { $_[0] * 72 / 25.4; }
sub in { $_[0] * 72; }

$DEFAULT_PAGESIZE = "A4";

%PaperSizes =
(
 A3        => [mm(297), mm(420)],
 A4        => [mm(210), mm(297)],
 A5        => [mm(148), mm(210)],
 B4        => [729, 1032],
 B5        => [516,  729],
 Letter    => [in(8.5), in(11)],
 Legal     => [in(8.5), in(14)],
 Executive => [in(7.5), in(10)],
 Tabloid   => [792, 1224],
 Statement => [396,  612],
 Folio     => [612,  936],
 Quarto    => [610,  780],
 "10x14"   => [in(720), in(14)],
);

%FontFamilies =
(
 Courier   => [qw(Courier
		  Courier-Bold
		  Courier-Oblique
		  Courier-BoldOblique)],

 Helvetica => [qw(Helvetica
		  Helvetica-Bold
		  Helvetica-Oblique
		  Helvetica-BoldOblique)],

 Times     => [qw(Times-Roman
		  Times-Bold
		  Times-Italic
		  Times-BoldItalic)],
);

      # size   0   1   2   3   4   5   6   7
@FontSizes = ( 5,  6,  8, 10, 12, 14, 18, 24);

sub BOLD   { 0x01; }
sub ITALIC { 0x02; }

%param = 
(
 papersize        => 'papersize',
 paperwidth       => 'paperwidth',
 paperheight      => 'paperheigth',
 leftmargin       => 'lmW',
 rightmargin      => 'rmW',
 horizontalmargin => 'mW',
 topmargin        => 'tmH',
 bottommargin     => 'bmH',
 verticalmargin   => 'mH',
 pageno           => 'printpageno',
 fontfamily       => 'family',
 fontscale        => 'fontscale',
);

sub new
{
    my $class = shift;

    # Set up defaults
    my $self = bless {
	family => "Times",
	mH => mm(30),
	mW => mm(20),
	printpageno => 1,
    }, $class;
    $self->papersize("a4");

    # Parse constructor arguments (might override defaults)
    while (($key, $val) = splice(@_, 0, 2)) {
	$key = lc $key;
	croak "Illegal parameter ($key => $val)" unless exists $param{$key};
	$key = $param{$key};
	{
	    $key eq "family" && do {
		$val = "\u\L$val";
		croak "Unknown font family ($val)"
		  unless exists $FontFamilies{$val};
		$self->{family} = $val;
		last;
	    };
	    $key eq "papersize" && do {
		$self->papersize($val) || croak "Unknown papersize ($val)";
		last;
	    };
	    $self->{$key} = lc $val;
	}
    }
    $self;
}

sub papersize
{
    my($self, $val) = @_;
    $val = "\u\L$val";
    my($width, $height) = @{$PaperSizes{$val}};
    return 0 unless defined $width;
    $self->{papersize} = $val;
    $self->{paperwidth} = $width;
    $self->{paperheight} = $height;
    1;
}


sub findfont
{
    my $self = shift;
    my $index = 0;
    $index |= BOLD   if $self->{bold};
    $index |= ITALIC if $self->{italic} || $self->{underline};
    my $family = $self->{teletype} ? 'Courier' : $self->{family};
    $family = "Times" unless defined $family;
    my $font = $FontFamilies{$family}[$index];
    my $size = $FontSizes[$self->{fsize}];
    my $fontsize = "$font-$size";
    if ($self->{currentfont} eq $fontsize) {
	return "";
    }
    $self->{currentfont} = $fontsize;
    $self->{pointsize} = $size;
    my $fontmod = "HTML::Font::$font";
    $fontmod =~ s/-/_/g;
    my $fontfile = $fontmod . ".pm";
    $fontfile =~ s,::,/,g;
    require $fontfile;
    $self->{wx} = \@{ "${fontmod}::wx" };

    return "/$font findfont $size scalefont SF";  #ok for now

    $font = $self->{fonts}{$fontsize} || do {
	my $fontID = "F" . ++$self->{fno};
	$self->{fonts}{$fontsize} = $fontID;
	$fontID;
    };
    "$font SF";
}

sub begin
{
    my $self = shift;
    $self->HTML::Formatter::begin;

    # Margins is points
    $self->{lm} = $self->{lmW} || $self->{mW};
    $self->{rm} = $self->{paperwidth}  - ($self->{rmW} || $self->{mW});
    $self->{tm} = $self->{paperheight} - ($self->{tmH} || $self->{mH});
    $self->{bm} = $self->{bmH} || $self->{mH};

    # Font setup
    $self->{fsize} = 3;
    $self->{fno} = 0;
    $self->{fonts} = {};
    $self->{en} = 0.55 * $FontSizes[$self->{fsize}];  # average char width

    # Initial position
    $self->{xpos} = $self->{lm};  # top of the current line
    $self->{ypos} = $self->{tm};

    $self->{pageno} = 1;

    print "%!PS-Adobe-3.0\n";
    print "%%Title: No title\n";  # should look for the <title> element
    print "%%Creator: HTML::FomatPS (libwww-perl)\n";
    print "%%CreationDate: " . localtime() . "\n";
    print "%%Pages: (atend)\n";
    print "%%PageOrder: Ascend\n";
    print "%%Orientation: Portrait\n";
    my($pw, $ph) = map { int($_); } @{$self}{qw(paperwidth paperheight)};
    
    print "%%DocumentMedia: Plain $pw $ph 0 white ()\n";
    print "%%DocumentSuppliedResources: procset newencode 1.0 0\n";
    print "%%EndComments\n\n";
    print "%%BeginProlog\n";
    print "/S/show load def\n";
    print "/M/moveto load def\n";
    print "/SF/setfont load def\n";
    print <<'EOT';
%%IncludeResource: encoding ISOLatin1Encoding
%%BeginResource: procset newencode 1.0 0
/NE { %def
   findfont begin
      currentdict dup length dict begin
         { %forall
            1 index/FID ne {def} {pop pop} ifelse
         } forall
         /FontName exch def
         /Encoding exch def
         currentdict dup
      end
   end
   /FontName get exch definefont pop
} bind def
%%EndResource
EOT
    print "%%EndProlog\n";
    $self->newpage;
}

sub end
{
    my $self = shift;
    $self->show;
    my($full,$short);
    while (($full, $short) = each %{$self->{fonts}}) {
	$full =~ s/-(\d+)$//;
	my $size = $1;
	print "% /$short/$full findfont $size scalefont def\n";
    }
    if ($self->{out}) {
	$self->endpage;
	print "\n%%Trailer\n";
	my $pages = $self->{pageno} - 1;
	print "%%Pages: $pages\n";
	print "%%EOF\n";
    }
}

sub header_start
{
    my($self, $level, $node) = @_;
    $self->vspace(1 + (6-$level) * 0.4);
    $self->eat_leading_space;
    $self->{bold}++;
    $self->{fsize} = 8 - $level;
    1;
}

sub header_end
{
    my($self, $level, $node) = @_;
    $self->vspace(1);
    $self->{bold}--;
    $self->{fsize} = 3;
    1;
}

sub skip_vspace
{
    my $self = shift;
    if (defined $self->{vspace}) {
	if ($self->{out}) {
	    $self->{ypos} -= ($self->{vspace} + 1) * 10;
	}
	$self->{xpos} = $self->{lm};
	$self->show;
	$self->moveto;
	$self->{vspace} = undef;
    }
}

sub pre_out
{
    my($self, $text) = @_;
    $self->skip_vspace;
    $self->tt_start;
    my $font = $self->findfont();
    if (length $font) {
	$self->show;
	print "$font\n"
    }
    while ($text =~ s/(.*)\n//) {
	$self->{line} .= $1;
	$self->newline;
    }
    $self->{line} .= $text;
    $self->tt_end;
}

sub newline
{
    my $self = shift;
    $self->show;
    $self->{ypos} -= $self->{pointsize};
    $self->{xpos} = $self->{lm};
    if ($self->{ypos} < $self->{bm}) {
	$self->newpage;
	$font = $self->findfont();
	die "This should not happen" unless length $font;
	print "$font\n";
    }
    $self->moveto;
}


sub out
{
    my($self, $text) = @_;

    $self->skip_vspace;

    my $font = $self->findfont();
    if (length $font) {
	$self->show;
	print "$font\n";
    }
    my $w = $self->width($text);
    my $xpos = $self->{xpos};
    my $rm   = $self->{rm};
    if ($xpos + $w > $rm) {
	$self->newline;
	next if $text =~ /^\s*$/;
    } else {
	$self->{xpos} += $w;
    }
    $self->{line} .= $text;
    $self->{out}++;
}

sub endpage
{
    my $self = shift;
    # End previous page
    print "showpage\n";
    $self->{pageno}++;
}

sub newpage
{
    my $self = shift;
    if ($self->{out}) {
	$self->endpage;
    }
    $self->{out} = 0;
    my $pageno = $self->{pageno};
    print "\n%%Page: $pageno $pageno\n";

    # Print area marker (just for debugging)
    my($llx, $lly, $urx, $ury) = @{$self}{qw(lm bm rm tm)};
    print "gsave 0.1 setlinewidth\n";
    print "clippath 0.9 setgray fill 1 setgray\n";
    print "$llx $lly moveto $urx $lly lineto $urx $ury lineto $llx $ury lineto closepath fill\n";
    print "grestore\n";

    # Print page number
    if ($self->{printpageno}) {
	my $x = $self->{paperwidth};
	if ($x) { $x -= 20; } else { $x = 10 };
	print "/Helvetica findfont 10 scalefont setfont\n";
	printf "%.1f 10 M($pageno)S\n", $x;
    }
    print "\n";

    $self->{xpos} = $llx;
    $self->{ypos} = $ury;
    $self->{currentfont} = "";
}

sub moveto
{
    my $self = shift;
    printf "%.1f %.1f M\n", $self->{xpos}, $self->{ypos};
}

sub show
{
    my $self = shift;
    my $line = $self->{line};
    return unless length $line;
    $line =~ s/([\(\)])/\\$1/g;
    print "($line)S\n";
    $self->{line} = "";
}

sub width
{
    my $self = shift;
    my $w = 0;
    my $wx = $self->{wx};
    my $sz = $self->{pointsize};
    while ($_[0] =~ /(.)/g) {
	$w += $wx->[ord $1] * $sz;
    }
    $w;
}


sub adjust_lm
{
    my $self = shift;
    $self->{lm} += $_[0] * $self->{en};
}

sub adjust_rm
{
    my $self = shift;
    $self->{rm} += $_[0] * $self->{en};
}

1;
