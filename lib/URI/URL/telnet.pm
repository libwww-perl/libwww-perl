package URI::URL::telnet;
require URI::URL::_generic;
@ISA = qw(URI::URL::_generic);

sub default_port { 23 }

require Carp;
sub illegal { Carp::croak("Illegal attribute for rlogin URLs"); }

*path      = \&illegal;
*query     = \&illegal;
*params    = \&illegal;
*frag      = \&illegal;

1;
