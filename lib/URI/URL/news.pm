package URI::URL::news;
require URI::URL;
@ISA = qw(URI::URL);

use URI::Escape;

sub new {
    my($class, $init, $base) = @_;
    my $self = bless { }, $class;
    $self->{'scheme'}  = lc($1) if $init =~ s/^\s*([\w\+\.\-]+)://;
    my $tmp = uri_unescape($init);
    $self->{'grouppart'} = $tmp;
    $self->{ ($tmp =~ m/\@/) ? 'article' : 'group' } = $tmp;
    $self->base($base) if $base;
    $self;
}

sub grouppart { shift->_elem('grouppart', @_) }
sub article   { shift->_elem('article',   @_) }
sub group     { shift->_elem('group',     @_) }

sub as_string {
    my $self = shift;
    "$self->{'scheme'}:" . uri_escape($self->{'grouppart'});
}

1;
