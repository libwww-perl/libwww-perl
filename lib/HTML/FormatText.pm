package HTML::FormatText;

# $Id: FormatText.pm,v 1.12 1996/06/09 14:49:58 aas Exp $

=head1 NAME

HTML::FormatText - Format HTML as text

=head1 SYNOPSIS

 require HTML::FormatText;
 $html = parse_htmlfile("test.html");
 $formatter = new HTML::FormatText;
 print $formatter->format($html);

=head1 DESCRIPTION

The HTML::FormatText is a formatter that outputs plain latin1 text.
All character attributes (bold/italic/underline) are ignored.
Formatting of HTML tables and forms is not implemented.

=head1 SEE ALSO

L<HTML::Formatter>

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut

require HTML::Formatter;

@ISA = qw(HTML::Formatter);

use strict;

sub begin
{
    my $self = shift;
    $self->HTML::Formatter::begin;
    $self->{lm}  =    3;  # left margin
    $self->{rm}  =   70;  # right margin
    $self->{curpos} = 0;  # current output position.
    $self->{maxpos} = 0;  # highest value of $pos (used by header underliner)
}

sub end
{
    shift->collect("\n");
}


sub header_start
{
    my($self, $level, $node) = @_;
    $self->vspace(1 + (6-$level) * 0.4);
    $self->{maxpos} = 0;
    $self->eat_leading_space;
    1;
}

sub header_end
{
    my($self, $level, $node) = @_;
    if ($level <= 2) {
	my $line;
	$line = '=' if $level == 1;
	$line = '-' if $level == 2;
	$self->vspace(0);
	$self->out($line x ($self->{maxpos} - $self->{lm}));
    }
    $self->vspace(1);
    1;
}

sub hr_start
{
    my $self = shift;
    $self->vspace(1);
    $self->out('-' x ($self->{rm} - $self->{lm}));
    $self->vspace(1);
}

sub pre_out
{
    my $self = shift;
    # should really handle bold/italic etc.
    if (defined $self->{vspace}) {
	if ($self->{out}) {
	    $self->nl() while $self->{vspace}-- > -0.5;
	    $self->{vspace} = undef;
	}
    }
    my $indent = ' ' x $self->{lm};
    my $pre = shift;
    $pre =~ s/\n/\n$indent/g;
    $self->collect($pre);
    $self->{out}++;
}

sub out
{
    my $self = shift;
    my $text = shift;

    if (defined $self->{vspace}) {
	if ($self->{out}) {
	    $self->nl while $self->{vspace}-- >= 0;
	    $self->goto_lm;
	} else {
	    $self->goto_lm;
	}
	$self->{vspace} = undef;
    }

    if ($self->{curpos} > $self->{rm}) { # line is too long, break it
	return if $text =~ /^\s*$/;  # white space at eol is ok
	$self->nl;
	$self->goto_lm;
    }

    if ($self->{pending_space}) {
	$self->{pending_space} = 0;
	$self->collect(' ');
	my $pos = ++$self->{curpos};
	$self->{maxpos} = $pos if $self->{maxpos} < $pos;
    }

    $self->{pending_space} = 1 if $text =~ s/\s+$//;
    return unless length $text;

    $self->collect($text);
    my $pos = $self->{curpos} += length $text;
    $self->{maxpos} = $pos if $self->{maxpos} < $pos;
    $self->{'out'}++;
}

sub goto_lm
{
    my $self = shift;
    my $pos = $self->{curpos};
    my $lm  = $self->{lm};
    if ($pos < $lm) {
	$self->{curpos} = $lm;
	$self->collect(" " x ($lm - $pos));
    }
}

sub nl
{
    my $self = shift;
    $self->{'out'}++;
    $self->{pending_space} = 0;
    $self->{curpos} = 0;
    $self->collect("\n");
}

sub adjust_lm
{
    my $self = shift;
    $self->{lm} += $_[0];
    $self->goto_lm;
}

sub adjust_rm
{
    shift->{rm} += $_[0];
}

1;
