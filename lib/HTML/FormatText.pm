package HTML::FormatText;

require HTML::Format;

@ISA = qw(HTML::Format);

use strict;

sub begin
{
    my $self = shift;
    $self->HTML::Format::begin;
    $self->{lm}  =    3;  # left margin
    $self->{rm}  =   70;  # right margin
    $self->{pos} =    0;  # current output position.
    $self->{maxpos} = 0;  # highest value of $pos (used by header underliner)
}

sub end
{
    print "\n";
}


sub header_start
{
    my($formatter, $level, $node) = @_;
    $formatter->vspace(1 + (6-$level) * 0.4);
    $formatter->{maxpos} = 0;
    $formatter->eat_leading_space;
    1;
}

sub header_end
{
    my($formatter, $level, $node) = @_;
    if ($level <= 2) {
	my $line;
	$line = '=' if $level == 1;
	$line = '-' if $level == 2;
	$formatter->vspace(0);
	$formatter->out($line x ($formatter->{maxpos} - $formatter->{lm}));
    }
    $formatter->vspace(1);
    1;
}

sub hr_start
{
    my $formatter = shift;
    $formatter->vspace(1);
    $formatter->out('-' x ($formatter->{rm} - $formatter->{lm}));
    $formatter->vspace(1);
}

sub pre_out
{
    my $formatter = shift;
    # should really handle bold/italic etc.
    if (defined $formatter->{vspace}) {
	if ($formatter->{out}) {
	    $formatter->nl() while $formatter->{vspace}-- > -0.5;
	    $formatter->{vspace} = undef;
	}
    }
    my $indent = ' ' x $formatter->{lm};
    my $pre = shift;
    $pre =~ s/^/$indent/gm;
    print $pre;
    $formatter->{out}++;
}

sub out
{
    my $formatter = shift;
    my $text = shift;

    if (defined $formatter->{vspace}) {
	if ($formatter->{out}) {
	    $formatter->nl while $formatter->{vspace}-- > 0;
	    $formatter->lm;
	} else {
	    $formatter->lm;
	}
	$formatter->{vspace} = undef;
    }

    if ($formatter->{pos} > $formatter->{rm}) {  # line is too long, break it
	return if $text =~ /^\s*$/;  # white space at eol is ok
	$formatter->nl;
	$formatter->lm;
    }
    
    if ($formatter->{pending_space}) {
	$formatter->{pending_space} = 0;
	print ' ';
	my $pos = ++$formatter->{pos};
	$formatter->{maxpos} = $pos if $formatter->{maxpos} < $pos;
    }

    $formatter->{pending_space} = 1 if $text =~ s/\s+$//;
    return unless length $text;

    print $text;
    my $pos = $formatter->{pos} += length $text;
    $formatter->{maxpos} = $pos if $formatter->{maxpos} < $pos;
    $formatter->{out}++;
}

sub lm
{
    my $formatter = shift;
    my $pos = $formatter->{pos};
    my $lm  = $formatter->{lm};
    if ($pos < $lm) {
	$formatter->{pos} = $lm;
	print " " x ($lm - $pos);
    }
}

sub nl
{
    my $formatter = shift;
    $formatter->{out}++;
    $formatter->{pending_space} = 0;
    $formatter->{pos} = 0;
    print "\n";
}

sub adjust_lm
{
    shift->{lm} += $_[0];
}

sub adjust_rm
{
    shift->{rm} += $_[0];
}

1;
