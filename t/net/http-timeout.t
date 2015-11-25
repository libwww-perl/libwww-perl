# perl
# Check timeouts via HTTP.
#

use strict;
use warnings;
use HTTP::Request;
use Test::More;
use FindBin qw($Bin);

plan skip_all => 'No net config file' unless -e "$Bin/config.pl";

require_ok("$Bin/config.pl");
use_ok('LWP::UserAgent');

ok($net::httpserver, 'httpserver set in config.pl');
ok($net::cgidir, 'cgidir set in config.pl');

my $ua = LWP::UserAgent->new(timeout=>4);   # create a useragent to test
isa_ok($ua,'LWP::UserAgent', 'new UserAgent');

my $url  = "http://$net::httpserver/$net::cgidir/timeout";
my $request = HTTP::Request->new('GET', $url);
isa_ok($request, 'HTTP::Request', 'new HTTP::Request');

my $response = $ua->request($request, undef);
isa_ok($response, 'HTTP::Response', 'got a response');

ok($response->is_error, 'The response is correctly an error');
like($response->as_string(), qr/timeout/, 'The error message is a timeout');

done_testing();
