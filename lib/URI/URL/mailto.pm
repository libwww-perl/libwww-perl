package URI::URL::mailto;
require URI::URL;
@ISA = qw(URI::URL);

use URI::Escape;

sub new {
    my($class, $init, $base) = @_;

    my $self = bless { }, $class;
    $self->{'scheme'} = lc($1) if $init =~ s/^\s*([\w\+\.\-]+)://;
    $self->{'address'} = uri_unescape($init);
    $self->base($base) if $base;
    $self;
}

sub address { shift->_elem('address', @_); }

# can use these as aliases
*encoded822addr = \&address;   # URI::URL v3 compatibility
*netloc         = \&address;

sub user {
    my $self = shift;
    $old = $self->{'address'};
    if (@_) {
	my $new = $old;
	$new =~ s/.*\@?/$_[0]\@/;
	$self->{'address'} = $new;
    }
    $old =~ s/\@.*//;
    $old;
}

sub host {
    my $self = shift;
    $old = $self->{'address'};
    if (@_) {
	my $new = $old;
	$new =~ s/\@.*/\@$_[0]/;
	$self->{'address'} = $new;
    }
    $old =~ s/.*\@//;
    $old;
}

sub as_string {
    my $self = shift;
    my $str = ($self->{'scheme'} || "mailto") . ":";
    $str .= uri_escape($self->{'address'}) if defined $self->{'address'};
    $str;
}

1;
