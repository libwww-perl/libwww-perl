package URI::URL::gopher;
@ISA = qw(URI::URL::_generic);

sub default_port { 70 }

sub _parse {
    my($self, $url)   = @_;
    $self->{'scheme'} = lc($1) if $url =~ s/^\s*([\w\+\.\-]+)://;
    $self->netloc($self->unescape($1)) if $url =~ s!^//([^/]*)!!;
    $self->{'frag'} = ($self->unescape($1)) if $url =~ s/#(.*)//;
    $self->path($self->unescape($url));
}

sub path {
    my($self, @val) = @_;
    my $old = $self->URI::URL::_generic::path;
    return $old unless @val;

    my $val = $val[0];
    $self->{'path'} = $val;

    if ($val =~ s!^/(.)!!) {
        $self->{'gtype'} = $1;
    } else {
        $self->{'gtype'} = "1";
        $val = "";
    }

    delete $self->{'selector'};
    delete $self->{'search'};
    delete $self->{'string'};

    my @parts = split(/\t/, $val, 3);
    $self->{'selector'} = shift @parts if @parts;
    $self->{'search'}   = shift @parts if @parts;
    $self->{'string'}   = shift @parts if @parts;

    $old;
}

sub gtype    { shift->_path_elem('gtype',    @_); }
sub selector { shift->_path_elem('selector', @_); }
sub search   { shift->_path_elem('search',   @_); }
sub string   { shift->_path_elem('string',   @_); }

sub _path_elem {
    my($self, $elem, @val) = @_;
    my $old = $self->_elem($elem, @val);
    return $old unless @val;

    # construct new path based on elements
    my $path = "/$self->{'gtype'}";
    $path .= "\t$self->{'selector'}" if defined $self->{'selector'};
    $path .= "\t$self->{'search'}"   if defined $self->{'search'};
    $path .= "\t$self->{'string'}"   if defined $self->{'string'};
    $self->{'path'} = $path;

    $old;
}

require Carp;
sub query { Carp::croak("Illegal method for gopher URLs") }

1;
