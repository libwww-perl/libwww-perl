package URI::URL::rlogin;
require URI::URL::_generic;
@ISA = qw(URI::URL::_generic);

require Carp;
sub illegal { Carp::croak("Illegal attribute for rlogin URLs"); }

*path      = \&illegal;
*query     = \&illegal;
*params    = \&illegal;
*frag      = \&illegal;

1;
