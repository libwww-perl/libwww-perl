#
# Check timeouts via HTTP.
#

print "1..1\n";

require LWP::StatusCode;
require LWP::Protocol::http;
require LWP::UserAgent;

my $ua = new LWP::UserAgent;    # create a useragent to test

$ua->timeout(5);

$url = new URI::URL('http://web.nexor.co.uk/' .
                    'users/mak/cgi-bin/timeout.pl');


my $request = new LWP::Request('GET', $url);

my $response = $ua->request($request, undef, undef);

my $str = $response->asString;

if ($response->isError and 
    $response->code == &LWP::StatusCode::RC_REQUEST_TIMEOUT and 
    $str =~ /timeout/) {
    print "ok 1\n";
}
else {
    print "nok ok 1\n";
}
