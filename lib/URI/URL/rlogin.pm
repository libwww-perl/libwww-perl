package URI::URL::rlogin;
@ISA = qw(URI::URL::_generic);

require Carp;
sub illegal { Carp::croak("Illegal attribute for rlogin URLs"); }

*path      = \&illegal;
*query     = \&illegal;
*params    = \&illegal;
*frag      = \&illegal;

1;
