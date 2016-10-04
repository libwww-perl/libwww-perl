use strict;
use warnings;
use Test::More;

use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol;
use URI;

LWP::Protocol::implementor(http => 'myhttp');

plan tests => 7;

# This test tries to make a custom protocol implementation by
# subclassing of LWP::Protocol.

my $ua = LWP::UserAgent->new;
$ua->proxy('ftp' => "http://www.sn.no/");

my $req = HTTP::Request->new(GET => 'ftp://foo/');
$req->header(Cookie => "perl=cool");
my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'sn.no: got a response');

#print $res->as_string;
is($res->code, 200, 'sn.no: code 200');
is($res->content, "Howdy\n", 'sn.no: content good');
exit;


{
    package myhttp;
    use base 'LWP::Protocol';
    use Test::More;

    sub new {
        my $self = shift->SUPER::new(@_);
        my($prot) = @_;
        is($prot, "http", 'protocol: http');
        $self;
    }

    sub request {
        my $self = shift;
        my($request, $proxy, $arg, $size, $timeout) = @_;
        #print $request->as_string;

        is($proxy, "http://www.sn.no/", 'protocol request: proxy good');
        is($request->uri, "ftp://foo/", 'protocol request: uri good');
        is($request->header("cookie"), "perl=cool", 'protocol request: cookie good');

        my $res = HTTP::Response->new(200 => "OK");
        $res->content_type("text/plain");
        $res->date(time);
        $self->collect_once($arg, $res, "Howdy\n");
        $res;
    }
}
