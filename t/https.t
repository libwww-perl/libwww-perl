#!perl -w

use strict;
use Test;

use LWP::UserAgent;

my $ua = LWP::UserAgent->new();
my $res = $ua->simple_request(HTTP::Request->new(GET => "https://www.apache.org"));

plan tests => 2;
ok($res->is_success);
ok($res->content =~ /Apache Software Foundation/);

$res->dump(prefix => "# ");
