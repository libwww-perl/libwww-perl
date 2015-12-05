# perl

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

my $url = "http://$net::httpserver$net::cgidir/moved";

my $ua = LWP::UserAgent->new(timeout=>30);   # create a useragent to test
isa_ok($ua,'LWP::UserAgent','new LWP::UserAgent');

my $request = HTTP::Request->new('GET', $url);
isa_ok($request,'HTTP::Request', 'new HTTP::Request');
# print $request->as_string;

my $response = $ua->request($request, undef, undef);

ok($response->is_success, "successful request");

done_testing();
