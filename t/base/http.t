#!./perl -w

print "1..12\n";

use strict;
#use Data::Dump ();

{
    package HTTP;
    use vars qw(@ISA);
    require Net::HTTP::Methods;
    @ISA=qw(Net::HTTP::Methods);

    my %servers = (
      a => { "/" => "HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 6\r\n\r\nHello\n",
	     "/bad1" => "HTTP/1.0 200 OK\nServer: foo\nHTTP/1.0 200 OK\nContent-type: text/foo\n\nabc\n",
	     "/09" => "Hello\r\nWorld!\r\n",
	     "/chunked" => "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0002; foo=3; bar\r\nHe\r\n1\r\nl\r\n2\r\nlo\r\n0000\r\nContent-MD5: xxx\r\n\r\n",
	     "/head" => "HTTP/1.1 200 OK\r\nContent-Length: 16\r\nContent-Type: text/plain\r\n\r\n",
	   },
    );

    sub http_connect {
	my($self, $cnf) = @_;
	my $server = $servers{$cnf->{PeerAddr}} || return undef;
	${*$self}{server} = $server;
	${*$self}{read_chunk_size} = $cnf->{ReadChunkSize};
	return $self;
    }

    sub peerport {
	return 80;
    }

    sub print {
	my $self = shift;
	#Data::Dump::dump("PRINT", @_);
	my $in = shift;
	my($method, $uri) = split(' ', $in);

	my $out;
	if ($method eq "TRACE") {
	    my $len = length($in);
	    $out = "HTTP/1.0 200 OK\r\nContent-Length: $len\r\n" .
                   "Content-Type: message/http\r\n\r\n" .
                   $in;
	}
        else {
	    $out = ${*$self}{server}{$uri};
	    $out = "HTTP/1.0 404 Not found\r\n\r\n" unless defined $out;
	}

	${*$self}{out} .= $out;
	return 1;
    }

    sub sysread {
	my $self = shift;
	#Data::Dump::dump("SYSREAD", @_);
	my $length = $_[1];
	my $offset = $_[2] || 0;

	if (my $read_chunk_size = ${*$self}{read_chunk_size}) {
	    $length = $read_chunk_size if $read_chunk_size < $length;
	}

	my $data = substr(${*$self}{out}, 0, $length, "");
	return 0 unless length($data);

	$_[0] = "" unless defined $_[0];
	substr($_[0], $offset) = $data;
	return length($data);
    }

    # ----------------

    sub request {
	my($self, $method, $uri, $headers, $opt) = @_;
	$headers ||= [];
	$opt ||= {};

	my($code, $message, @h);
	my $buf = "";
	eval {
	    $self->write_request($method, $uri, @$headers) || die "Can't write request";
	    ($code, $message, @h) = $self->read_response_headers(%$opt);

	    my $tmp;
	    my $n;
	    while ($n = $self->read_entity_body($tmp, 32)) {
		#Data::Dump::dump($tmp, $n);
		$buf .= $tmp;
	    }

	    push(@h, $self->get_trailers);

	};

	my %res = ( code => $code,
		    message => $message,
		    headers => \@h,
		    content => $buf,
		  );

	if ($@) {
	    $res{error} = $@;
	}

	return \%res;
    }
}

# Start testing
my $h;
my $res;

$h = HTTP->new(Host => "a", KeepAlive => 1) || die;
$res = $h->request(GET => "/");

#Data::Dump::dump($res);

print "not " unless $res->{code} eq "200" && $res->{content} eq "Hello\n";
print "ok 1\n";

$res = $h->request(GET => "/404");
print "not " unless $res->{code} eq "404";
print "ok 2\n";

$res = $h->request(TRACE => "/foo");
print "not " unless $res->{code} eq "200" &&
                    $res->{content} eq "TRACE /foo HTTP/1.1\r\nKeep-Alive: 300\r\nConnection: Keep-Alive\r\nHost: a:80\r\n\r\n";
print "ok 3\n";

# try to turn off keep alive
$h->keep_alive(0);
$res = $h->request(TRACE => "/foo");
print "not " unless $res->{code} eq "200" &&
                    $res->{content} eq "TRACE /foo HTTP/1.1\r\nConnection: close\r\nHost: a:80\r\n\r\n";
print "ok 4\n";

# try a bad one
$res = $h->request(GET => "/bad1", [], {laxed => 1});
print "not " unless $res->{code} eq "200" && $res->{message} eq "OK" &&
                    "@{$res->{headers}}" eq "Server foo Content-type text/foo" &&
                    $res->{content} eq "abc\n";
print "ok 5\n";

$res = $h->request(GET => "/bad1");
print "not " unless $res->{error} =~ /Bad header/ && !$res->{code};
print "ok 6\n";
$h = undef;  # it is in a bad state now

$h = HTTP->new(Host => "a") || die;  # reconnect
$res = $h->request(GET => "/09", [], {laxed => 1});
print "not " unless $res->{code} eq "200" && $res->{message} eq "Assumed OK" &&
                    $res->{content} eq "Hello\r\nWorld!\r\n" &&
                    $h->peer_http_version eq "0.9";
print "ok 7\n";

$res = $h->request(GET => "/09");
print "not " unless $res->{error} =~ /^Bad response status line: 'Hello'/;
print "ok 8\n";
$h = undef;  # it's in a bad state again

$h = HTTP->new(Host => "a", KeepAlive => 1, ReadChunkSize => 1) || die;  # reconnect
$res = $h->request(GET => "/chunked");
print "not " unless $res->{code} eq "200" && $res->{content} eq "Hello" &&
                    "@{$res->{headers}}" eq "Transfer-Encoding chunked Content-MD5 xxx";
print "ok 9\n";

# once more
$res = $h->request(GET => "/chunked");
print "not " unless $res->{code} eq "200" && $res->{content} eq "Hello" &&
                    "@{$res->{headers}}" eq "Transfer-Encoding chunked Content-MD5 xxx";
print "ok 10\n";

# test head
$res = $h->request(HEAD => "/head");
print "not " unless $res->{code} eq "200" && $res->{content} eq "" &&
                    "@{$res->{headers}}"  eq "Content-Length 16 Content-Type text/plain";
print "ok 11\n";

$res = $h->request(GET => "/");
print "not " unless $res->{code} eq "200" && $res->{content} eq "Hello\n";
print "ok 12\n";
#use Data::Dump; Data::Dump::dump($res);

