package URI::URL::wais;
require URI::URL::_generic;
@ISA = qw(URI::URL::_generic);

use URI::Escape;

sub default_port { 210 }

sub _parse {
    my($self, $init) = @_;
    $self->URI::URL::_generic::_parse($init);
    my @parts = $self->path_components;
    $self->{'database'} = uri_unescape($parts[0]) if defined $parts[0];
    $self->{'wtype'}    = uri_unescape($parts[1]) if defined $parts[1];
    $self->{'wpath'}    = uri_unescape($parts[2]) if defined $parts[2];
}

# Setting these should really update path
sub database { shift->_elem('database', @_); }
sub wtype    { shift->_elem('wtype',    @_); }
sub wpath    { shift->_elem('wpath',    @_); }

1;
