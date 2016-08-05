#!perl

BEGIN { eval { require Data::Dump; 1 } || do { print "1..0 # SKIP Data::Dump is not installed\n"; exit 0 } }

print "1..1\n";
print "ok 1\n";

use strict;
use LWP::UserAgent ();

LWP::Protocol::implementor(http => 'myhttp');

my $ua = LWP::UserAgent->new(keep_alive => 1);
$ua->proxy('http' => "http://proxy.activestate.com");

print "----\n";

my $req = HTTP::Request->new(GET => 'http://gisle:aas@www.activestate.com');
my $res = $ua->request($req);

print $res->as_string;
exit;


#----------------------------------
package myhttp;

BEGIN {
    use vars qw(@ISA);
    require LWP::Protocol::http;
    @ISA=qw(LWP::Protocol::http);
}

sub _conn_class {
    "myconn";
}

package myconn;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub format_request {
    my $self = shift;
    return "REQ";
}

sub syswrite {
    my $self = shift;
    return length($_[0]);
}

sub read_response_headers {
    my $self = shift;
    return (302, "OK", "Content-type", "text/plain");
}

sub read_entity_body {
    my $self = shift;
    return 0;
}

sub peer_http_version {
    my $self = shift;
    return "1.1";
}

sub increment_response_count {
    my $self = shift;
    ++$self->{count};
}

sub get_trailers {
    my $self = shift;
    return ();
}

1;
