use strict;
use warnings;
use Test::More;

use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol;
use URI;

plan tests => 2;

LWP::Protocol::implementor(http => 'myhttp');

my $ua = LWP::UserAgent->new(keep_alive => 1);

$ua->proxy('http' => "http://proxy.activestate.com");
my $req = HTTP::Request->new(GET => 'http://gisle:aas@www.activestate.com');
my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response', 'activeState: got a response');
ok($res->as_string, 'activeState: has content');

exit;

{
    package myhttp;
    use base 'LWP::Protocol::http';

    sub _conn_class {
        "myconn";
    }
}

{
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
}
{
    package myhttp::SocketMethods;

    sub ping {
        my $self = shift;
        !$self->can_read(0);
    }

    sub increment_response_count {
        my $self = shift;
        return ++${*$self}{'myhttp_response_count'};
    }
}
{
    package myhttp::Socket;
    use base qw(myhttp::SocketMethods Net::HTTP);
}
