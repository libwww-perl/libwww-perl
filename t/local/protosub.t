#!perl

use strict;
use Test;
plan tests => 6;

# This test tries to make a custom protocol implementation by
# subclassing of LWP::Protocol.


use LWP::UserAgent ();
use LWP::Protocol ();

LWP::Protocol::implementor(http => 'myhttp');

my $ua = LWP::UserAgent->new;
$ua->proxy('ftp' => "http://www.sn.no/");

my $req = HTTP::Request->new(GET => 'ftp://foo/');
$req->header(Cookie => "perl=cool");

my $res = $ua->request($req);

#print $res->as_string;
ok($res->code, 200);
ok($res->content, "Howdy\n");
exit;


#----------------------------------
package myhttp;

use Test qw(ok);

BEGIN {
   use vars qw(@ISA);
   @ISA=qw(LWP::Protocol);
}

sub new
{
    my $class = shift;
    print "CTOR: $class->new(@_)\n";
    my($prot) = @_;
    ok($prot, "http");
    my $self = $class->SUPER::new(@_);
    for (keys %$self) {
	my $v = $self->{$_};
	$v = "<undef>" unless defined($v);
	print "$_: $v\n";
    }
    $self;
}

sub request
{
    my $self = shift;
    my($request, $proxy, $arg, $size, $timeout) = @_;
    #print $request->as_string;

    ok($proxy, "http://www.sn.no/");
    ok($request->uri, "ftp://foo/");
    ok($request->header("cookie"), "perl=cool");

    my $res = HTTP::Response->new(200 => "OK");
    $res->content_type("text/plain");
    $res->date(time);
    $self->collect_once($arg, $res, "Howdy\n");
    $res;
}
