#
# Test mirroring a file
#

require LWP::Protocol::http;
require LWP::UserAgent;
require LWP::StatusCode;

print "1..2\n";

my $ua = new LWP::UserAgent;    # create a useragent to test

my $url = 'http://localhost/';
my $copy = "/usr/tmp/lwp-test-$$"; # downloaded copy

my $response = $ua->mirror($url, $copy);

if ($response->code == &LWP::StatusCode::RC_OK) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

# OK, so now do it again, should get Not-Modified
$response = $ua->mirror($url, $copy);
if ($response->code == &LWP::StatusCode::RC_NOT_MODIFIED) {
    print "ok 2\n";
} else {
    print "nok ok 2\n";
}
unlink($copy);
