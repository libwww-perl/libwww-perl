package URI::URL::telnet;
@ISA = qw(URI::URL::_generic);

sub default_port { 23 }

use Carp;
my $illegal = "Illegal method for telnet URLs";

sub path     { croak $illegal; }
sub params   { croak $illegal; }
sub query    { croak $illegal; }
sub frag     { croak $illegal; }

1;
