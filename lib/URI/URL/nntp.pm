package URI::URL::nntp;
@ISA = qw(URI::URL::_generic);

sub default_port { 119 }

sub _parse {
    my($self, $init) = @_;
    $self->URI::URL::_generic::_parse($init);

    my $path = $self->{'path'};
    $path .= "?$self->{'query'}" if defined $self->{'query'};
    delete $self->{'path'};
    delete $self->{'query'};

    my @parts = split(/\//, $path, 3);

    $self->{'group'} = $self->unescape($parts[1]);
    $self->{'digits'}= $self->unescape($parts[2]);
}

sub group   { shift->_elem('group',  @_); }
sub digits  { shift->_elem('digits', @_); }
sub article { shift->_elem('digits', @_); }

sub as_string {
    my $self = shift;
    my $str = "$self->{'scheme'}:";
    $str .= "//$self->{'netloc'}" if defined $self->{'netloc'};
    $str .= "/" . $self->escape($self->{'group'}) . "/" .
      $self->escape($self->{'digits'});
    $str;
}

use Carp;
my $illegal = "Illegal method for nntp URLs";

sub path     { croak $illegal; }
sub params   { croak $illegal; }
sub query    { croak $illegal; }
sub frag     { croak $illegal; }
sub user     { croak $illegal; }
sub password { croak $illegal; }

1;
