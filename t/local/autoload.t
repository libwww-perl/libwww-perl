#
# See if autoloading of protocol schemes work
#

print "1..1\n";

require LWP::UserAgent;
# note no LWP::Protocol::file;

$url = 'file://localhost/';

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->timeout(30);               # timeout in seconds
$ua->useAlarm(1);               # don't use alarms
#$ua->useEval(0);                # don't eval, just die when thing go wrong
                                # (easier to read while debugging)

my $request = new HTTP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);
if ($response->isSuccess) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}
