package URI::URL::wais;
@ISA = qw(URI::URL::_generic);

sub default_port { 210 }

sub _parse {
    my($self, $init) = @_;
    $self->URI::URL::_generic::_parse($init);
    my @parts         = split(/\//, $self->{'path'});
    $self->{'database'} = $self->unescape($parts[1]);
    $self->{'wtype'}    = $self->unescape($parts[2]);
    $self->{'wpath'}    = $self->unescape($parts[3]);
}

# Setting these should really update path
sub database { shift->_elem('database', @_); }
sub wtype    { shift->_elem('wtype',    @_); }
sub wpath    { shift->_elem('wpath',    @_); }
1;
