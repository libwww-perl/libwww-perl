package HTML::Filter;

require HTML::Parser;
@ISA=qw(HTML::Parser);

$VERSION = sprintf("%d.%02d", q$Revision: 2.1 $ =~ /(\d+)\.(\d+)/);

sub declaration { $_[0]->output("<!$_[1]>")     }
sub comment     { $_[0]->output("<!--$_[1]-->") }
sub start       { $_[0]->output($_[4])          }
sub end         { $_[0]->output($_[2])          }
sub text        { $_[0]->output($_[1])          }

sub output  { print $_[1]; }

1;
