package URI::URL::mailto;
require URI::URL;
@ISA = qw(URI::URL);

sub new {
    my($class, $init, $base) = @_;

    my $self = bless { }, $class;
    $self->{'scheme'} = lc($1) if $init =~ s/^\s*([\w\+\.\-]+)://;
    $self->{'encoded822addr'} = $init;
    $self->base($base) if $base;
    $self;
}

sub encoded822addr { shift->_elem('encoded822addr', @_); }

*netloc = \&encoded822addr;  # can use this as an alias

sub as_string {
    my $self = shift;
    my $str = '';
    $str .= "$self->{'scheme'}:" if defined $self->{'scheme'};
    $str .= "$self->{'encoded822addr'}" if defined $self->{'encoded822addr'};
    $str;
}

1;
