package HTML::FormatPS;

require HTML::Format;

@ISA = qw(HTML::Format);

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

      # size   0  1  2  3   4   5   6   7
@FontSizes = ( 5, 6, 8,10, 12, 14, 18, 24);

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
    $font = "$font-$size";
    if ($self->{currentfont} eq $font) {
	return "";
    }
    $self->{currentfont} = $font;
    $self->{pointsize} = $size;
    $font = $self->{fonts}{$font} || do {
	my $fontID = "F" . ++$self->{fno};
	$self->{fonts}{$font} = $fontID;
	$fontID;
    };
    "$font setfont";
}

sub begin
{
    my $self = shift;
    $self->HTML::Format::begin;
    $self->{family} = "Helvetica";

    # Margins is points
    $self->{lm} = 10;
    $self->{rm} = 520;
    $self->{bm} = 40;
    $self->{tm} = 800;

    $self->{en} = 7;    # width of an avarage char 'n' in the normal font

    # Font size
    $self->{fsize} = 3;
    $self->{fno} = 0;
    $self->{fonts} = {};
}

sub end
{
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
    print "$font>>>$text\n";
    $self->tt_end;
}

sub out
{
    my($self, $text) = @_;
    return if $text =~ /^\s*$/;
    my $font = $self->findfont();
    print "$font($text)show\n";
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
