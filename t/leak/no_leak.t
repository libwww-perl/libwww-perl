use strict;
use warnings;

# To ensure "no leak" in real LWP code, we should test it against HTTP servers.
# However, HTTPS is not required here, so let's use an HTTP site neverssl.com.
use Test::RequiresInternet 'neverssl.com' => 80;

use Test::More;
use Test::Needs 'Test::LeakTrace';

use File::Temp ();
use LWP::UserAgent;

plan skip_all => 'skip leak test in COVERAGE' if $ENV{COVERAGE};

my ($tempfh, $tempfile) = File::Temp::tempfile(UNLINK => 0);
close $tempfh;

Test::LeakTrace::no_leaks_ok(sub {
    my $ua = LWP::UserAgent->new;
    my $res = $ua->get("http://neverssl.com/", ':content_file' => $tempfile);
});

unlink $tempfile;

done_testing;
