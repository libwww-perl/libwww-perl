package URI::URL::nntp;
require URI::URL::_generic;
@ISA = qw(URI::URL::_generic);

use URI::Escape;

sub default_port { 119 }

sub _parse {
    my($self, $init) = @_;
    $self->URI::URL::_generic::_parse($init, qw(netloc path frag));

    my @parts = $self->path_components;
    shift @parts if @parts && $parts[0] eq '';

    $self->{'group'} = uri_unescape($parts[0]);
    $self->{'digits'}= uri_unescape($parts[1]);
}

sub group   { shift->_elem('group',  @_); }
sub digits  { shift->_elem('digits', @_); }
sub article { shift->_elem('digits', @_); }

sub as_string {
    my $self = shift;
    my $str = "$self->{'scheme'}:";
    $str .= "//$self->{'netloc'}" if defined $self->{'netloc'};
    $str .= "/" . uri_escape($self->{'group'}) . "/" .
		  uri_escape($self->{'digits'});
    $str;
}

# Standard methods are not legal for nntp URLs
require Carp;
sub illegal { Carp::croak("Illegal attribute for nntp URLs"); }

*path      = \&illegal;
*epath     = \&illegal;
*query     = \&illegal;
*equery    = \&illegal;
*params    = \&illegal;
*eparams   = \&illegal;
*frag      = \&illegal;
*user      = \&illegal;
*password  = \&illegal;

1;
