package URI::URL::news;
@ISA = qw(URI::URL::_generic);

sub _parse {
    my($self, $init) = @_;
    $self->{'scheme'}  = lc($1) if ($init =~ s/^\s*([\w\+\.\-]+)://);
    my $tmp = $self->unescape($init);
    $self->{'grouppart'} = $tmp;
    $self->{ ($tmp =~ m/\@/) ? 'article' : 'group' } = $tmp;
}

sub grouppart { shift->_elem('grouppart', @_) }
sub article   { shift->_elem('article',   @_) }
sub group     { shift->_elem('group',     @_) }

sub as_string {
    my $self = shift;
    "$self->{'scheme'}:" . $self->escape($self->{'grouppart'});
}

# Standard methods are not legal for news URLs
require Carp;
sub illegal { Carp::croak("Illegal attribute for news URLs"); }

*path      = \&illegal;
*query     = \&illegal;
*params    = \&illegal;
*frag      = \&illegal;

*user      = \&illegal;
*password  = \&illegal;
*host      = \&illegal;
*port      = \&illegal;
*full_path = \&illegal;

1;
