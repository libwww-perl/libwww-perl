#!/local/perl/bin/perl

use HTTP::Daemon;
#$HTTP::Daemon::DEBUG++;

my $d = new HTTP::Daemon;
print "Please contact me at: <URL:", $d->url, ">\n";

while (my $c = $d->accept) {
    while (my $r = $c->get_request) {
	print $r->as_string;
	$c->autoflush;
        while (<STDIN>) {
	    last if $_ eq ".\n";
	    print $c $_;
	}
	print "\nEOF\n";
    }
    print "CLOSE: ", $c->reason, "\n";
    $c->close;
    $c = undef;
}
