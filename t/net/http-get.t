# perl
#
# Check GET via HTTP.
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

my $ua = LWP::UserAgent->new();   # create a useragent to test
isa_ok($ua,'LWP::UserAgent', 'new UserAgent');

my $url  = "http://$net::httpserver/$net::cgidir/test?query";
my $request = HTTP::Request->new('GET', $url);
isa_ok($request, 'HTTP::Request', 'Got a proper request setup');

my $response = $ua->request($request);
isa_ok($response, 'HTTP::Response', 'got a response');

ok($response->is_success, '$r->is_success');

my $str = $response->as_string;
like($str, qr/^REQUEST_METHOD=GET$/m, 'proper REQUEST_METHOD');
like($str, qr/^QUERY_STRING=query$/m, 'proper QUERY_STRING');

done_testing();
