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
require Carp;
sub illegal { Carp::croak("Illegal attribute for mailto URLs"); }

*path      = \&illegal;
*query     = \&illegal;
*params    = \&illegal;
*frag      = \&illegal;

*user      = \&illegal; # should we allow this one?
*password  = \&illegal;
*host      = \&illegal; # and this one?
*port      = \&illegal;
*full_path = \&illegal;

1;
