#!/local/perl/bin/perl

use HTTP::Daemon;
#$HTTP::Daemon::DEBUG++;

my $d = HTTP::Daemon->new(Timeout => 60);
print "Please contact me at: <URL:", $d->url, ">\n";

while (my $c = $d->accept) {
  CONNECTION:
    while (my $r = $c->get_request) {
	print $r->as_string;
	$c->autoflush;
      RESPONSE:
        while (<STDIN>) {
	    last RESPONSE if $_ eq ".\n";
	    last CONNECTION if $_ eq "..\n";
	    print $c $_;
	}
	print "\nEOF\n";
    }
    print "CLOSE: ", $c->reason, "\n";
    $c->close;
    $c = undef;
}
