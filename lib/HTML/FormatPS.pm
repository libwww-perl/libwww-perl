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
 B4        => [729,     1032   ],
 B5        => [516,     729    ],
 Letter    => [in(8.5), in(11) ],
 Legal     => [in(8.5), in(14) ],
 Executive => [in(7.5), in(10) ],
 Tabloid   => [in(11),  in(17) ],
 Statement => [in(5.5), in(8.5)],
 Folio     => [in(8.5), in(13) ],
 "10x14"   => [in(10),  in(14) ],
 Quarto    => [610,     780    ],
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
@FontSizes = ( 5,  6,  8, 10, 12, 14, 18, 24, 32);

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
	fontscale   => 1,
    }, $class;
    $self->papersize($DEFAULT_PAGESIZE);

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


sub fontsize
{
    my $self = shift;
    my $size = $self->{font_size}[-1];
    $size = 8 if $size > 8;
    $size = 3 if $size < 0;
    $FontSizes[$size] * $self->{fontscale};
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
    my $size = $self->fontsize;
    my $font_with_size = "$font-$size";
    if ($self->{currentfont} eq $font_with_size) {
	return "";
    }
    $self->{currentfont} = $font_with_size;
    $self->{pointsize} = $size;
    my $fontmod = "HTML::Font::$font";
    $fontmod =~ s/-/_/g;
    my $fontfile = $fontmod . ".pm";
    $fontfile =~ s,::,/,g;
    require $fontfile;
    $self->{wx} = \@{ "${fontmod}::wx" };
    $font = $self->{fonts}{$font_with_size} || do {
	my $fontID = "F" . ++$self->{fno};
	$self->{fonts}{$font_with_size} = $fontID;
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
    $self->{fno} = 0;
    $self->{fonts} = {};
    $self->{en} = 0.55 * $self->fontsize(3);

    # Initial position
    $self->{xpos} = $self->{lm};  # top of the current line
    $self->{ypos} = $self->{tm};

    $self->{output} = ();
    $self->{pageno} = 1;
    $self->newpage;
}

sub end
{
    my $self = shift;
    $self->show;
    $self->endpage if $self->{out};
    my $pages = $self->{pageno} - 1;

    print "%!PS-Adobe-3.0\n";
    #print "%%Title: No title\n";  # should look for the <title> element
    print "%%Creator: HTML::FormatPS (libwww-perl)\n";
    print "%%CreationDate: " . localtime() . "\n";
    print "%%Pages: $pages\n";
    print "%%PageOrder: Ascend\n";
    print "%%Orientation: Portrait\n";
    my($pw, $ph) = map { int($_); } @{$self}{qw(paperwidth paperheight)};
    
    print "%%DocumentMedia: Plain $pw $ph 0 white ()\n";
    print "%%DocumentNeededResources: encoding ISOLatin1Encoding\n";
    my($full, %seenfont);
    for $full (sort keys %{$self->{fonts}}) {
	$full =~ s/-\d+$//;
	next if $seenfont{$full}++;
	print "%%+ font $full\n";
    }    
    print "%%DocumentSuppliedResources: procset newencode 1.0 0\n";
    print "%%EndComments\n";
    print <<'EOT';

%%BeginProlog
/S/show load def
/M/moveto load def
/SF/setfont load def

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
%%EndProlog
EOT

    print "\n%%BeginSetup\n";
    my($full,$short);
    for $full (sort keys %{$self->{fonts}}) {
	$short = $self->{fonts}{$full};
	$full =~ s/-(\d+)$//;
	my $size = $1;
	print "ISOLatin1Encoding/$full-ISO/$full NE\n";
	print "/$short/$full-ISO findfont $size scalefont def\n";
    }
    print "%%EndSetup\n";

    for (@{$self->{output}}) {
	print;
    }
    print "\n%%Trailer\n%%EOF\n";
}

sub collect
{
    push(@{shift->{output}}, @_);
}

sub header_start
{
    my($self, $level, $node) = @_;
    # If we are close enough to be bottom of the page, start a new page
    # instead of this:
    $self->vspace(1 + (6-$level) * 0.4);
    $self->eat_leading_space;
    $self->{bold}++;
    push(@{$self->{font_size}}, 8 - $level);
    1;
}

sub header_end
{
    my($self, $level, $node) = @_;
    $self->vspace(1);
    $self->{bold}--;
    pop(@{$self->{font_size}});
    1;
}

sub skip_vspace
{
    my $self = shift;
    if (defined $self->{vspace}) {
	if ($self->{out}) {
	    $self->{ypos} -= ($self->{vspace} + 1) * 10 * $self->{fontscale};
	    if ($self->{ypos} < $self->{bm}) {
		$self->show;
		$self->newpage;
		return;
	    }
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
	$self->collect("$font\n");
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
	$self->collect("$font\n");
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
	$self->collect("$font\n");
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
    $self->collect("showpage\n");
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
    $self->collect("\n%%Page: $pageno $pageno\n");

    # Print area marker (just for debugging)
    my($llx, $lly, $urx, $ury) = map { sprintf "%.1f", $_}
                                 @{$self}{qw(lm bm rm tm)};
    $self->collect("gsave 0.1 setlinewidth\n");
    $self->collect("clippath 0.9 setgray fill 1 setgray\n");
    $self->collect("$llx $lly moveto $urx $lly lineto $urx $ury lineto $llx $ury lineto closepath fill\n");
    $self->collect("grestore\n");

    # Print page number
    if ($self->{printpageno}) {
	my $x = $self->{paperwidth};
	if ($x) { $x -= 20; } else { $x = 10 };
	$self->collect("/Helvetica findfont 10 scalefont setfont ");
	$self->collect(sprintf "%.1f 10.0 M($pageno)S\n", $x);
    }
    $self->collect("\n");

    $self->{xpos} = $llx;
    $self->{ypos} = $ury;
    $self->{currentfont} = "";
}

sub moveto
{
    my $self = shift;
    $self->collect(sprintf "%.1f %.1f M\n", $self->{xpos}, $self->{ypos});
}

sub show
{
    my $self = shift;
    my $line = $self->{line};
    return unless length $line;
    $line =~ s/([\(\)])/\\$1/g;
    $self->collect("($line)S\n");
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
