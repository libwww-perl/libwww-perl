package HTML::Format;

require HTML::Element;

use strict;

sub new
{
    my $class = shift;
    bless { }, $class;
}

sub format
{
    my($html, $formatter) = @_;
    $formatter->begin();
    $html->traverse(
	sub {
	    my($node, $start, $depth) = @_;
	    if (ref $node) {
		my $tag = $node->tag;
		my $func = $tag . '_' . ($start ? "start" : "end");
		return $formatter->$func($node);
	    } else {
		$formatter->textflow($node);
	    }
	    1;
	}
     );
    $formatter->end();
}

sub begin
{
    my $formatter = shift;
    # Flags
    $formatter->{anchor} = 0;
    $formatter->{underline} = 0;
    $formatter->{bold} = 0;
    $formatter->{italic} = 0;
    $formatter->{center} = 0;

    $formatter->{makers} = [];
    $formatter->{vspace} = undef;
    $formatter->{eat_leading_space} = 0;
}

sub end
{
}

sub html_start { 1; }  sub html_end {}
sub head_start { 0; }
sub body_start { 1; }  sub body_end {}

sub header_start
{
    my($formatter, $level, $node) = @_;
    1,
}

sub header_end
{
    my($formatter, $level, $node) = @_;
}

sub h1_start { shift->header_start(1, @_) }
sub h2_start { shift->header_start(2, @_) }
sub h3_start { shift->header_start(3, @_) }
sub h4_start { shift->header_start(4, @_) }
sub h5_start { shift->header_start(5, @_) }
sub h6_start { shift->header_start(6, @_) }

sub h1_end   { shift->header_end(1, @_) }
sub h2_end   { shift->header_end(2, @_) }
sub h3_end   { shift->header_end(3, @_) }
sub h4_end   { shift->header_end(4, @_) }
sub h5_end   { shift->header_end(5, @_) }
sub h6_end   { shift->header_end(6, @_) }

sub br_start
{
    my $formatter = shift;
    $formatter->vspace(0);
    $formatter->eat_leading_space;
    
}

sub hr_start
{
    my $formatter = shift;
    $formatter->vspace(1);
    $formatter->eat_leading_space;
}

sub img_start
{
    shift->out(shift->attr('alt') || "[IMAGE]");
}

sub a_start
{
    shift->{anchor}++;
    1;
}

sub a_end
{
    shift->{anchor}--;
}

sub u_start
{
    shift->{underline}++;
    1;
}

sub u_end
{
    shift->{underline}--;
}

sub b_start
{
    shift->{bold}++;
    1;
}

sub b_end
{
    shift->{bold}--;
}

sub tt_start
{
    shift->{teletype}++;
    1;
}

sub tt_end
{
    shift->{teletype}--;
}

sub i_start
{
    shift->{italic}++;
    1;
}

sub i_end
{
    shift->{italic}--;
}

sub center_start
{
    shift->{center}++;
    1;
}

sub center_end
{
    shift->{center}--;
}

# Aliases for logical markup
BEGIN {
    *cite_start   = \&i_start;
    *cite_end     = \&i_end;
    *code_start   = \&tt_start;
    *code_end     = \&tt_end;
    *em_start     = \&i_start;
    *em_end       = \&i_end;
    *kbd_start    = \&tt_start;
    *kbd_end      = \&tt_end;
    *samp_start   = \&tt_start;
    *samp_end     = \&tt_end;
    *strong_start = \&b_start;
    *strong_end   = \&b_end;
    *var_start    = \&tt_start;
    *var_end      = \&tt_end;
}

sub p_start
{
    my $formatter = shift;
    $formatter->vspace(1);
    $formatter->eat_leading_space;
    1;
}

sub p_end
{
    shift->vspace(1);
}

sub pre_start
{
    my $formatter = shift;
    $formatter->{pre}++;
    $formatter->vspace(1);
    1;
}

sub pre_end
{
    my $formatter = shift;
    $formatter->{pre}--;
    $formatter->vspace(1);
}

BEGIN {
    *listing_start = \&pre_start;
    *listing_end   = \&pre_end;
    *xmp_start     = \&pre_start;
    *xmp_end       = \&pre_end;
}

sub blockquote_start
{
    my $formatter = shift;
    $formatter->vspace(1);
    $formatter->eat_leading_space;
    $formatter->adjust_lm( +2 );
    $formatter->adjust_rm( -2 );
    1;
}

sub blockquote_end
{
    my $formatter = shift;
    $formatter->vspace(1);
    $formatter->adjust_lm( -2 );
    $formatter->adjust_rm( +2 );
}

sub address_start
{
    my $formatter = shift;
    $formatter->vspace(1);
    $formatter->eat_leading_space;
    $formatter->i_start(@_);
    1;
}

sub address_end
{
    my $formatter = shift;
    $formatter->i_end(@_);
    $formatter->vspace(1);
}

sub nobr_start
{
    1;
}

sub nobr_end
{
}

# Handling of list elements

sub ul_start
{
    my $formatter = shift;
    $formatter->vspace(1);
    push(@{$formatter->{markers}}, "*");
    $formatter->adjust_lm( +2 );
    1;
}

sub ul_end
{
    my $formatter = shift;
    pop(@{$formatter->{markers}});
    $formatter->adjust_lm( -2 );
    $formatter->vspace(1);
}

sub li_start
{
    my $formatter = shift;
    $formatter->out("$formatter->{markers}[-1] ");
    $formatter->adjust_lm(+2);
    $formatter->eat_leading_space;
    1;
}

sub li_end
{
    my $formatter = shift;
    $formatter->vspace(1);
    $formatter->adjust_lm( -2);
    my $markers = $formatter->{markers};
    if ($markers->[-1] =~ /^\d+/) {
	# increment ordered markers
	$markers->[-1]++;
    }
}

sub ol_start
{
    my $formatter = shift;
   
    $formatter->vspace(1);
    push(@{$formatter->{markers}}, 1);
    $formatter->adjust_lm(+2);
    1;
}

sub ol_end
{
    my $formatter = shift;
    $formatter->adjust_lm(-2);
    pop(@{$formatter->{markers}});
    $formatter->vspace(1);
}


sub dl_start
{  
    my $formatter = shift;
    $formatter->adjust_lm(+2);
    $formatter->vspace(1);
    1;
}

sub dl_end
{
    my $formatter = shift;
    $formatter->adjust_lm(-2);
    $formatter->vspace(1);
}

sub dt_start
{
    my $formatter = shift;
    $formatter->vspace(1);
    $formatter->eat_leading_space;
    1;
}

sub dt_end
{
}

sub dd_start
{
    my $formatter = shift;
    $formatter->adjust_lm(+6);
    $formatter->vspace(0);
    $formatter->eat_leading_space;
    1;
}

sub dd_end
{
    shift->adjust_lm(-6);
}


# Things not formated at all
sub table_start { shift->out('[TABLE NOT SHOWN]'); 0; }
sub form_start  { shift->out('[FORM NOT SHOWN]');  0; }
sub font_start  { 1; }  sub font_end {}



sub textflow
{
    my $formatter = shift;
    if ($formatter->{pre}) {
	$formatter->pre_out($_[0]);
    } else {
	for (split(/(\s+)/, $_[0])) {
	    next unless length $_;
	    if ($formatter->{eat_leading_space}) {
		$formatter->{eat_leading_space} = 0;
		next if /^\s/;
	    }
	    $formatter->out($_);
	}
    }
}



sub eat_leading_space
{
    shift->{eat_leading_space} = 1;
}


sub vspace
{
    my($formatter, $new) = @_;
    return if defined $formatter->{vspace} and $formatter->{vspace} > $new;
    $formatter->{vspace} = $new;
}


1;
