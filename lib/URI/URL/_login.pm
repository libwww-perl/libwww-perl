package URI::URL::_login;
require URI::URL::_generic;
@ISA = qw(URI::URL::_generic);


# Generic terminal logins.  This is used as a base class for 'telnet',
# 'tn3270', and 'rlogin' URL schemes.


sub _parse {
    my($self, $init) = @_;
    # All we want from _generic is the 'netloc' handling.
    $self->URI::URL::_generic::_parse($init, 'netloc');
}    


require Carp;
sub illegal { Carp::croak("Illegal attribute for login URLs"); }

*path      = \&illegal;
*epath     = \&illegal;
*query     = \&illegal;
*equery    = \&illegal;
*params    = \&illegal;
*eparams   = \&illegal;
*frag      = \&illegal;

1;
