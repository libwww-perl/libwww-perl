# perl
use strict;
use warnings;
use HTTP::Request;
use Test::More;

BEGIN {use_ok('LWP::UserAgent') || BAIL_OUT( 'Cannot use LWP::UserAgent' );}

{
    package MyUA;
    use base 'LWP::UserAgent';

    my @try = (['foo', 'bar'], ['', ''], ['guest', ''], ['guest', 'guest']);

    sub get_basic_credentials {
        my($self,$realm, $uri, $proxy) = @_;
        print "$realm:$uri:$proxy => ";
        my $p = shift @try;
        print join("/", @$p), "\n";
        return @$p;
    }
}

my $ua = MyUA->new(keep_alive => 1);
isa_ok($ua, 'MyUA', 'Got a new User Agent');

my $req = HTTP::Request->new(GET => "http://jigsaw.w3.org/HTTP/Digest/");
isa_ok($req,'HTTP::Request', 'setup a new request');
my $res = $ua->request($req);
isa_ok($res,'HTTP::Response', 'got a response');

#print $res->as_string;

like($res->content, qr/Your browser made it!/, 'Got the proper text');
is($res->header("Client-Response-Num"), 5, 'got the proper response number');

done_testing();
