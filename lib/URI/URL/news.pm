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

use Carp;
my $illegal = "Illegal method for news URLs";

sub path     { croak $illegal; }
sub params   { croak $illegal; }
sub query    { croak $illegal; }
sub frag     { croak $illegal; }
sub netloc   { croak $illegal; }
sub user     { croak $illegal; }
sub password { croak $illegal; }
sub host     { croak $illegal; }
sub port     { croak $illegal; }

1;
