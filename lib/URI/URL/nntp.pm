package URI::URL::nntp;
@ISA = qw(URI::URL::_generic);

sub default_port { 119 }

sub _parse {
    my($self, $init) = @_;
    $self->URI::URL::_generic::_parse($init);
    my @parts      = split(/\//, $self->{path});
    $self->{'group'} = $self->unescape($parts[1]);
    $self->{'digits'}= $self->unescape($parts[2]);
}

sub group  { shift->_elem('group',  @_); }
sub digits { shift->_elem('digits', @_); }
1;
