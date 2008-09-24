use strict;
use Test;

plan tests => 5;

use LWP::UserAgent;

my $ua = LWP::UserAgent->new(keep_alive => 1);

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Basic/");

my $res = $ua->request($req);

#print $res->as_string;

ok($res->code, 401);

$req->authorization_basic('guest', 'guest');
$res = $ua->simple_request($req);

print $req->as_string, "\n";

#print $res->as_string;
ok($res->code, 200);
ok($res->content =~ /Your browser made it!/);

{
   package MyUA;
   use vars qw(@ISA);
   @ISA = qw(LWP::UserAgent);

   my @try = (['foo', 'bar'], ['', ''], ['guest', ''], ['guest', 'guest']);

   sub get_basic_credentials {
	my($self,$realm, $uri, $proxy) = @_;
	#print "$realm/$uri/$proxy\n";
	my $p = shift @try;
	#print join("/", @$p), "\n";
	return @$p;
   }

}

$ua = MyUA->new(keep_alive => 1);

$req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Basic/");
$res = $ua->request($req);

#print $res->as_string;

ok($res->content =~ /Your browser made it!/);
ok($res->header("Client-Response-Num"), 5);

