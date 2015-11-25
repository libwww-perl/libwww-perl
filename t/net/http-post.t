#!perl
#
# Check POST via HTTP.
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

my $url  = "http://$net::httpserver/$net::cgidir/test";
my $form = 'searchtype=Substring';

my $request = HTTP::Request->new('POST', $url, undef, $form);
isa_ok($request, 'HTTP::Request', 'Got a proper request setup');
$request->header('Content-Type', 'application/x-www-form-urlencoded');

my $response = $ua->request($request, undef, undef);
isa_ok($response, 'HTTP::Response', 'got a response');

my $str = $response->as_string;
ok($response->is_success, "response was successful");
like($response->as_string, qr/^REQUEST_METHOD=POST$/m, 'was a proper POST request');

my $len = 0;
$len = $1 if $str =~ /^CONTENT_LENGTH=(\d+)$/m;
is($len, length($form), "content length matches the form length");

done_testing();
