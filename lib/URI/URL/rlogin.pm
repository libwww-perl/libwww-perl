package URI::URL::rlogin;
@ISA = qw(URI::URL::_generic);

use Carp;
my $illegal = "Illegal method for rlogin URLs";

sub path     { croak $illegal; }
sub params   { croak $illegal; }
sub query    { croak $illegal; }
sub frag     { croak $illegal; }

1;
