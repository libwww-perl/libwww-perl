#
# See if autoloading of protocol schemes work
#

print "1..1\n";

require LWP::UserAgent;
# note no LWP::Protocol::file;

# localhost will not work on win32 (when networking is disabled)
$url = $^O eq 'MSWin32' ? 'file:.' : 'file://localhost/';

print "Trying to fetch " . (new URI::URL $url)->local_path . " ...\n";

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->timeout(30);               # timeout in seconds
#$ua->use_alarm(0);               # don't use alarms
#$ua->use_eval(0);                # don't eval, just die when thing go wrong
				# (easier to read while debugging)

my $request = new HTTP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);
if ($response->is_success) {
    print "ok 1\n";
} else {
    print $response->error_as_HTML;
    print "not ok 1\n";
}
