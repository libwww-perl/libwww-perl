package HTML::Element;

use Carp;


sub new
{
    my $class = shift;
    my $tag   = shift;
    croak "No tag" unless defined $tag or length $tag;
    warn "HTML::Element $tag\n";
    my $self  = bless { _tag => lc $tag }, $class;
    my($attr, $val);
    while (($attr, $val) = splice(@_, 0, 2)) {
	$val = 1 unless defined $val;
	$self->{lc $attr} = $val;
    }
    if ($tag eq 'html') {
	$self->{'_buf'} = '';
	$self->{'_pos'} = undef;
    }
    $self;
}

sub tag
{
    shift->{_tag};
}

sub parent
{
    shift->attr('_parent', @_);
}

sub pos
{
    my $self = shift;
    my $pos = $self->attr('_pos', @_);
    $pos || $self;
}

sub attr
{
    my $self = shift;
    my $attr = lc shift;
    my $old = $self->{$attr};
    if (@_) {
	$self->{$attr} = $_[0];
    }
    $old;
}

sub content
{
    shift->{'_content'};
}

sub pushContent
{
    my $self = shift;
    $self->{'_content'} = [] unless exists $self->{'_content'};
    push(@{$self->{'_content'}}, @_);
}

sub deleteContent
{
    my $self = shift;
    delete $self->{'_content'};
}

sub dump
{
    my $self = shift;
    my $depth = shift || 0;
    print "  " x $depth;
    print "\U$self->{_tag}";
    for (keys %$self) {
	next if /^_/;
	print qq{ $_="$self->{$_}"};
    }
    print "\n";
    for (@{$self->{_content}}) {
	if (ref $_) {
	    $_->dump($depth+1);
	} else {
	    print "  " x ($depth + 1);
	    print qq{"$_"\n};
	}
    }
}

1;
