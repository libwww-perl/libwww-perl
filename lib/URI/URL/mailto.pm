package URI::URL::mailto;
@ISA = qw(URI::URL::_generic);

sub _parse {
    my($self, $init) = @_;
    $self->{'scheme'}  = lc($1) if ($init =~ s/^\s*([\w\+\.\-]+)://);
    $self->{'encoded822addr'} = $self->unescape($init);
}

sub encoded822addr { shift->_elem('encoded822addr', @_); }

sub as_string {
    my $self = shift;
    my $str = '';
    $str .= "$self->{'scheme'}:" if defined $self->{'scheme'};
    $str .= "$self->{'encoded822addr'}" if defined $self->{'encoded822addr'};
    $str;
}

sub netloc { shift->encoded822addr(@_)};

# Standard methods are not legal for mailto URLs
use Carp;
my $illegal = "Illegal attribute for mailto URLs";

sub path      { croak $illegal; }
sub query     { croak $illegal; }
sub params    { croak $illegal; }
sub frag      { croak $illegal; }

sub user      { croak $illegal; }  # should we allow this one?
sub password  { croak $illegal; }
sub host      { croak $illegal; }  # and this one?
sub port      { croak $illegal; }
sub full_path { croak $illegal; }

1;
