# $Id: SecureSocket.pm,v 1.1 1997/08/05 14:09:11 aas Exp $
#
# Derived by Joshua Kronengold from Socket.pm and SSLeay
#


require Socket;
require Net::SSLeay;


package LWP::SecureSocket;

=head1 NAME

LWP::SecureSocket - SSL TCP/IP socket interface

=head1 SYNOPSIS

 $socket = new LWP::SecureSocket;
 $socket->connect('localhost', 7); # echo
 $quote = 'I dunno, I dream in Perl sometimes...';
 $socket->write("$quote\n");
 $socket->read_until("\n", \$buffer);
 $socket->read(\$buffer);
 $socket = undef;  # close

=head1 DESCRIPTION

This class implements TCP/IP sockets.  It groups socket generation,
TCP address manipulation and buffered reading. Errors are handled by
dying (throws exceptions).

This class should really not be required, something like this should
be part of the standard Perl5 library.

Running this module standalone executes a self test which requires
localhost to serve chargen and echo protocols.

=head1 METHODS

=cut


$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

use Socket qw(pack_sockaddr_in unpack_sockaddr_in
	      PF_INET SOCK_STREAM INADDR_ANY
	      inet_ntoa inet_aton);
Socket->require_version(1.5);

use Carp ();
use Symbol qw(gensym);

use LWP::Debug ();
use LWP::IO ();
# use Socket;
use Net::SSLeay;


my $tcp_proto = (getprotobyname('tcp'))[2];


=head2 $sock = new LWP::SecureSocket()

Constructs a new socket object.

=cut

sub new
{
    my($class, $socket, $host, $port) = @_;

    unless ($socket) {
	$socket = gensym();
	LWP::Debug::debug("SecureSocket $socket");

	socket($socket, PF_INET, SOCK_STREAM, $tcp_proto) or
	  Carp::croak("socket: $!");
    }

    my $self = bless {
	'socket' => $socket,
	'host'   => $host,
	'port'   => $port,
	'buffer' => '',
	'size'   => 4096,
    }, $class;

    $self;
}

sub DESTROY
{
    my $socket = shift->{'socket'};
    close($socket);
}

sub host { shift->{'host'}; }
sub port { shift->{'port'}; }


=head2 $sock->connect($host, $port)

Connect the socket to given host and port.

=cut

sub connect
{
    my($self, $host, $port) = @_;
    Carp::croak("no host") unless defined $host && length $host;
    Carp::croak("no port") unless defined $port && $port > 0;

    LWP::Debug::trace("($host, $port)");

    $self->{'host'} = $host;
    $self->{'port'} = $port;

    my @addr = $self->_getaddress($host, $port);
    Carp::croak("Can't resolv address for $host")
      unless @addr;
    $socket=$self->{'socket'};
    LWP::Debug::debug("Connecting to host '$host' on port '$port'...");
    for (@addr) {
	if (connect($self->{'socket'}, $_)) 
	{
#	    print STDERR "\nCreating context....".
#		"(connected socket($self->{'socket'}) to \n$host, $port, and ".
#		    "socket is ".."\n";
	    my $ctx= Net::SSLeay::CTX_new() or 
	      Carp::croak "Failed to create SSL_CTX $!";
	    $self->{'context'}=$ctx;
	    $self->{SSL} = Net::SSLeay::new($ctx) or 
	      Carp::croak "Failed to create SSL $!";
	    ($err=Net::SSLeay::set_fd($self->{SSL}, ($fn=fileno($socket)))) or 
		(Carp::croak "Can't set_fd somehow $!"); 
#	    print STDERR "\nConnecting....fileno=($fn)\n";
	    my $res= Net::SSLeay::connect($self->{SSL});
#	    print STDERR "result of connect: ($res)\n";
	    return;
	}
    }
    Carp::croak("Could not connect to $host:$port");
}


=head2 $sock->shutdown()

Shuts down the connection.

=cut

sub shutdown
{
    my($self, $how) = @_;
    $how = 2 unless defined $how;
    shutdown($self->{'socket'}, $how);
    delete $self->{'host'};
    delete $self->{'port'};
}


=head2 $sock->bind($host, $port)

Binds a name to the socket.

=cut

sub bind
{
    my($self, $host, $port) = @_;
    my $name = $self->_getaddress($host, $port);
    bind($self->{'socket'}, $name);
}


=head2 $sock->listen($queuesize)

Set up listen queue for socket.

=cut

sub listen
{
    listen(shift->{'socket'}, @_);
}


=head2 $sock->accept($timeout)

Accepts a new connection.  Returns a new LWP::SecureSocket object if successful.
Timeout not implemented yet.  would require modifying new, and not
    necessary for app, so I\'m not bothering to modify.  Might work
anyways, though.

=cut

sub accept
{
    my $self = shift;
    my $timeout = shift;
    my $ns = gensym();
    my $addr = accept($ns, $self->{'socket'});
    if ($addr) {
	my($port, $addr) = unpack_sockaddr_in($addr);
	return new LWP::SecureSocket $ns, inet_ntoa($addr), $port;
    } else {
	Carp::croak("Can't accept: $!");
    }
}


=head2 $sock->getsockname()

Returns a 2 element array ($host, $port)

=cut

sub getsockname
{
    my($port, $addr) = unpack_sockaddr_in(getsockname(shift->{'socket'}));
    (inet_ntoa($addr), $port);
}


=head2 $sock->read_until($delim, $data_ref, $size, $timeout)

Reads data from the socket, up to a delimiter specified by a regular
expression.  If $delim is undefined all data is read.  If $size is
defined, data will be read internally in chunks of $size bytes.  This
does not mean that we will return the data when size bytes are read.

Note that $delim is discarded from the data returned.

=cut

sub read_until
{
    my ($self, $delim, $data_ref, $size, $timeout) = @_;

    {
	my $d = $delim;
	$d =~ s/\r/\\r/g;
	$d =~ s/\n/\\n/g;
	LWP::Debug::trace("('$d',...)");
    }

    my $socket = $self->{'socket'};
    my $ssl = $self->{SSL};
    $delim = '' unless defined $delim;
    $size ||= $self->{'size'};

    my $buf = \$self->{'buffer'};

    if (length $delim) {
	while ($$buf !~ /$delim/) {
	    my $data=Net::SSLeay::read($ssl) or die "Unexpected EOF 1";     
	    $$buf .=$data;
	    
#	    LWP::IO::read($socket, $$buf, $size, length($$buf), $timeout)
#		or die "Unexpected EOF";
	}
	($$data_ref, $self->{'buffer'}) = split(/$delim/, $$buf, 2);
    } else {
	$data_ref = $buf;
	$self->{'buffer'} = '';
    }

    1;
}


=head2 $sock->read($bufref, [$size, $timeout])

Reads data of the socket.  Not more than $size bytes.  Might return
less if the data is available.  Dies on timeout.

=cut

sub read
{
    my($self, $data_ref, $size, $timeout) = @_;
    $size ||= $self->{'size'};

    LWP::Debug::trace('(...)');
    if (length $self->{'buffer'}) {
	# return data from buffer until it is empty
	#print "Returning data from buffer...$self->{'buffer'}\n";
	$$data_ref = substr($self->{'buffer'}, 0, $size);
	substr($self->{'buffer'}, 0, $size) = '';
	return length $$data_ref;
    }
    
    my $ssl = $self->{SSL};
#    print STDERR "reading...";
    (my $data=Net::SSLeay::read($ssl));
#    print STDERR "read ($data)\n";
    $$data_ref.=$data;
    return(length $data);
}


=head2 $sock->pushback($data)

Put data back into the socket.  Data will returned next time you
read().  Can be used if you find out that you have read too much.

=cut

sub pushback
{
    LWP::Debug::trace('(' . length($_[1]) . ' bytes)');
    my $self = shift;
    substr($self->{'buffer'}, 0, 0) = shift;
}


=head2 $sock->write($data, [$timeout])

Write data to socket.  The $data argument might be a scalar or code.

If data is a reference to a subroutine, then we will call this routine
to obtain the data to be written.  The routine will be called until it
returns undef or empty data.  Data might be returned from the callback
as a scalar or as a reference to a scalar.

Write returns the number of bytes written to the socket.

=cut

sub write
{
    my $self = shift;
    my $ssl = $self->{SSL};

    my $timeout = $_[1];  # we don't want to copy data in $_[0]
    LWP::Debug::trace('()');
    my $bytes_written = 0;
    if (!ref $_[0]) {
	my $got = Net::SSLeay::write($ssl,  $_[0]);
	$bytes_written=length $_[0] if $got;
#	$bytes_written = LWP::IO::write($self->{'socket'}, $_[0], $timeout);
    } elsif (ref($_[0]) eq 'CODE') {
	# write data until $callback returns empty data '';
	my $callback = shift;
	while (1) {
	    my $data = &$callback;
	    last unless defined $data;
	    my $dataRef = ref($data) ? $data : \$data;
	    my $len = length $$dataRef;
	    last unless $len;
	    my $n = $self->write($$dataRef, $timeout);
	    $bytes_written += $n;
	    last if $n != $len;
	}
    } else {
	Carp::croak('Illegal LWP::SecureSocket->write() argument');
    }
    $bytes_written;
}



=head2 _getaddress($h, $p)

Given a host and a port, it will return the address (sockaddr_in)
suitable as the C<name> argument for connect() or bind(). Might return
several addresses in array context if the hostname is bound to several
IP addresses.

=cut


sub _getaddress
{
    my($self, $host, $port) = @_;

    my(@addr);
    if (!defined $host) {
	# INADDR_ANY
	$addr[0] = pack_sockaddr_in($port, INADDR_ANY);
    }
    elsif ($host =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
	# numeric IP address
	$addr[0] = pack_sockaddr_in($port, inet_aton($1));
    } else {
	# hostname
	LWP::Debug::debug("resolving host '$host'...");
	(undef,undef,undef,undef,@addr) = gethostbyname($host);
	for (@addr) {
	    LWP::Debug::debug("   ..." . inet_ntoa($_));
	    $_ = pack_sockaddr_in($port, $_);
	}
    }
    wantarray ? @addr : $addr[0];
}


#####################################################################

package main;

eval join('',<DATA>) || die $@ unless caller();

=head1 SELF TEST

This self test is only executed when this file is run standalone. It
tests its functions against some standard TCP services implemented by
inetd. If you do not have them around the tests will fail.

=cut

1;

__END__

LWP::Debug::level('+');

&chargen;
&echo;
print "SecureSocket.pm $LWP::SecureSocket::VERSION ok\n";

sub chargen
{
    my $socket = new LWP::SecureSocket;
    $socket->connect('localhost', 19); # chargen
    $socket->read_until('A', \$buffer, 8);

    die 'Read Error' unless $buffer eq ' !"#$%&\'()*+,-./0123456789:;<=>?@';
    $socket->read_until('Z', \$buffer, 8);
    die 'Read Error' unless $buffer eq 'BCDEFGHIJKLMNOPQRSTUVWXY';
}

sub echo
{
    $socket = new LWP::SecureSocket;
    $socket->connect('localhost', 7); # echo
    $quote = 'I dunno, I dream in Perl sometimes...';
	     # --Larry Wall in  <8538@jpl-devvax.JPL.NASA.GOV>
    $socket->write("$quote\n");
    $socket->read_until("\n", \$buffer);
    die 'Read Error' unless $buffer eq $quote;
}
