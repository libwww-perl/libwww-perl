#!/usr/local/bin/perl -w
#
# Check GET via HTTP of an object protected
# with Basic Authentication
#

print "1..1\n";

package LWP::askUA;

# This is an example of how to override getBasicCredentials
# to ask a user

require LWP::Protocol::http;
require LWP::UserAgent;

@ISA = qw(LWP::UserAgent);

sub getBasicCredentials {
    my($self, $realm) = @_;

    print "Authentication required for '$realm'\n";
    $| = 1;

    my($uid, $pwd);
    print "Username: ";
    chomp($uid = <STDIN>);
    print "Password: ";
    chomp($pwd = <STDIN>);

    return ($uid, $pwd);
}


use LWP::Debug;

#LWP::Debug::level('+trace');

require LWP::Protocol::http;

my $ua = new LWP::UserAgent;    # create a useragent to test

$url = new URI::URL('http://web.nexor.co.uk:9999/' .
                    'experimental/protected.txt');

# Need an nph script to test this!

$ua->credentials('RegisteredUsers', 'test', 'test');

my $request = new LWP::Request('GET', $url);

my $response = $ua->request($request);

if ($response->isSuccess) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}
