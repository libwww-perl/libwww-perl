package HTML::FormatPS;

require HTML::Formatter;

@ISA = qw(HTML::Formatter);

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

sub findfont
{
    my $self = shift;
    my $index = 0;
    $index |= BOLD   if $self->{bold};
    $index |= ITALIC if $self->{italic};
    my $family = $self->{teletype} ? 'Courier' : $self->{family};
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

    return "/$font findfont $size scalefont setfont";  #ok for now

    $font = $self->{fonts}{$fontsize} || do {
	my $fontID = "F" . ++$self->{fno};
	$self->{fonts}{$fontsize} = $fontID;
	$fontID;
    };
    "$font setfont";
}

sub begin
{
    my $self = shift;
    $self->HTML::Formatter::begin;

    # Margins is points
    $self->{lm} = 100;
    $self->{rm} = 520;
    $self->{bm} = 150;
    $self->{tm} = 700;

    # Font setup
    $self->{family} = "Times";
    $self->{fsize} = 3;
    $self->{fno} = 0;
    $self->{fonts} = {};
    $self->{en} = 0.55 * $FontSizes[$self->{fsize}];  # average char width

    # Initial position
    $self->{xpos} = $self->{lm};  # top of the current line
    $self->{ypos} = $self->{tm};

    $self->{pageno} = 1;

    print "%!PS-Adobe-3.0\n";
    print "%%BeginProlog\n";
    print "/S/show load def\n";
    print "/M/moveto load def\n";
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
}

sub end
{
    my $self = shift;
    $self->show;
    print "\n";
    my($full,$short);
    while (($full, $short) = each %{$self->{fonts}}) {
	$full =~ s/-(\d+)$//;
	my $size = $1;
	print "% /$short/$full findfont $size scalefont def\n";
    }
    print "showpage\n";
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

sub pre_out
{
    my($self, $text) = @_;
    $self->tt_start;
    my $font = $self->findfont();
    print "%% PRE NYI: $font\n";
    $self->tt_end;
}

sub out
{
    my($self, $text) = @_;

    if (defined $self->{vspace}) {
	if ($self->{out}) {
	    $self->{ypos} -= ($self->{vspace}+1)*10;
	}
	$self->{xpos} = $self->{lm};
	$self->show;
	$self->moveto;
	$self->{vspace} = undef;
    }

    my $font = $self->findfont();
    if (length $font) {
	$self->show;
	print "$font\n";
    }
    my $w = $self->width($text);
    my $xpos = $self->{xpos};
    my $rm   = $self->{rm};
    if ($xpos + $w > $rm) {
	$self->show;
	$self->{ypos} -= 10;
	$self->{xpos} = $self->{lm};
	$self->moveto;
    } else {
	$self->{line} .= $text;
	$self->{xpos} += $w;
    }
    $self->{out}++;
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
