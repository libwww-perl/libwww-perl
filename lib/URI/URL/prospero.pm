package URI::URL::prospero;
@ISA = qw(URI::URL::_generic);

sub default_port { 1525 }       # says rfc1738, section 3.11
1;
