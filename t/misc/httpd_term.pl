#!/local/perl/bin/perl

use lib 'blib/lib';
use HTTP::Daemon;


$d = new HTTP::Daemon;
print "Please contact me at: <URL:", $d->url, ">\n";

while ($c = $d->accept) {
    $r = $c->get_request;
    if ($r) {
	print $r->as_string;
	$c->autoflush;
        while (<STDIN>) {
	    last if $_ eq ".\n";
	    print $c $_;
	}
	print "\nEOF\n";
	$r = undef;
    }
    $c->close;
    $c = undef;
}
 
