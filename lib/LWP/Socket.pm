#!/local/bin/perl -w
#
# $Id: Socket.pm,v 1.7 1995/09/02 13:21:59 aas Exp $

package LWP::Socket;

=head1 NAME

LWP::Socket - TCP/IP socket interface

=head1 SYNOPSIS

 $socket = new LWP::Socket;
 $socket->connect('localhost', 7); # echo
 $quote = 'I dunno, I dream in Perl sometimes...';
 $socket->write("$quote\n");
 $socket->readUntil("\n", \$buffer);
 $socket = undef;  # close

=head1 DESCRIPTION

This class implements TCP/IP sockets.  It groups socket generation,
TCP address manipulation, and reading using select and sysread, with
internal buffering.

This class should really not be required, something like this should
be part of the standard Perl5 library.

Running this module standalone executes a self test which requires
localhost to serve chargen and echo protocols.

=cut

#####################################################################

$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

use Socket;
use Carp;

require LWP::Debug;

my $tcp_proto = (getprotobyname('tcp'))[2];

#####################################################################

=head1 METHODS

=head2 new()

Constructs a socket object.

=cut

sub new
{
    my($class) = @_;

    LWP::Debug::trace("($class)");

    my $socket = _gensym();
    LWP::Debug::debug("Socket $socket");

    socket($socket, PF_INET, SOCK_STREAM, $tcp_proto) or
        croak "socket: $!";

    my $self = bless {
        'socket' => $socket,
        'host' => undef,
        'port' => undef,
        'buffer' => '',
        'size' => 4096,
    }, $class;

    $self;
}

sub DESTROY
{
    my $socket = shift->{'socket'};
    close($socket);
    _ungensym($socket);
}


=head2 connect($host, $port)

Connect the socket to given host and port.

=cut

sub connect
{
    my($self, $host, $port) = @_;
    LWP::Debug::trace("($host, $port)");

    croak "no host" unless defined $host && length $host;
    croak "no port" unless defined $port && $port > 0;

    $self->{'host'} = $host;
    $self->{'port'} = $port;

    my @addr = $self->_getaddress($host, $port);
    croak "can't resolv address for $host:$port"
      unless @addr;

    LWP::Debug::debugl("Connecting to host '$host' on port '$port'...");
    for (@addr) {
	connect($self->{'socket'}, $addr[0]) and return;
    }
    croak "Could not connect to $host:$port: $!\n";
}

=head2 shutdown()

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

=head2 readUntil($delim, $bufferref, $size, $timeout)

Reads data from the socket, up to a delimiter specified by a regular
expression.  If $delim is undefined all data is read.  If $size is
defined, data will be read in chunks of $size bytes.

Note that $delim is discarded from the data returned.

Uses select() to allow timeouts.  Uses sysread() and internal
buffering for safety.

=cut

sub readUntil
{
    my ($self, $delim, $bufferref, $size, $timeout) = @_;

    my $socket = $self->{'socket'};
    $delim = '' unless defined $delim;
    $size ||= $self->{'size'};

    LWP::Debug::trace('(...)');

    my $totalbuffer = $self->{'buffer'};       # result so far
    $self->{'buffer'} = '';

    until (length $delim and $totalbuffer =~ /$delim/) {

        my $rin = '';
        vec($rin, fileno($socket), 1) = 1;

        LWP::Debug::debug('selecting');

        my $nfound = select($rin, undef, undef, $timeout);
        if ($nfound == 0) {
            return 0;  # timeout
        } elsif ($nfound < 0) {
            die "Select failed: $!";
        } else {
            LWP::Debug::debug('reading');
            my $buffer = '';
            my $read = sysread($socket, $buffer, $size);
	    last if $read <= 0;
            $totalbuffer .= $buffer if defined $buffer;
            LWP::Debug::conns("Read $read bytes: '$buffer'");
        }
    }

    if (length $delim) {
        ($$bufferref, $self->{'buffer'}) = split(/$delim/, $totalbuffer, 2);
    } else {
        $$bufferref = $totalbuffer;
    }

    LWP::Debug::debug("\nResult: " .
                      (defined $$bufferref ? "'$$bufferref'" : 'undef') .
                      "\nBuffered: " . 
                      (defined $self->{'buffer'} ?
                       "'$self->{'buffer'}'" : 'undef') );

    1;
}

=head2 read($bufref, $size, $timeout)

Reads data of the socket.  Not more than $size bytes.  Might return
less if the data is available.

=cut

sub read
{
    my($self, $bufferref, $size, $timeout) = @_;
    $size ||= $self->{'size'};

    LWP::Debug::trace('(...)');
    if (length $self->{'buffer'}) {
	# return data from buffer until it is empty
	print "Returning data from buffer...$self->{'buffer'}\n";
	$$bufferref = substr($self->{'buffer'}, 0, $size);
	substr($self->{'buffer'}, 0, $size) = '';
	return 1;
    }

    my $socket = $self->{'socket'};

    if (defined @Tk::ISA) {
	# we are running under Tk
	Tk->fileevent($socket, 'readable',
		      sub { sysread($socket, $$bufferref, $size); }
		     );
	my $timer = Tk->after($timeout*1000, sub {$$bufferref = ''} );

	# Tk->tkwait('variable' => $bufferref);
	#
	# This does not work because tkwait needs a real widget as self.
	# I believe this to be a bug in Tk-b8.  As a workaround assume
	# that a widget exists with the name $main::main.
	$main::main->tkwait('variable' => $bufferref);

	Tk->after('cancel', $timer);
	Tk->fileevent($socket, 'readable', ''); # no more callbacks
	return 1;
    }

    my $rin = '';
    vec($rin, fileno($socket), 1) = 1;

    LWP::Debug::debug('selecting');

    my $nfound = select($rin, undef, undef, $timeout);
    if ($nfound == 0) {
	return 0;  # timeout
    } elsif ($nfound < 0) {
	die "Select failed: $!";
    } else {
	LWP::Debug::debug('reading');
	my $n = sysread($socket, $$bufferref, $size);
	LWP::Debug::conns("Read $n bytes: '$$bufferref'");
	return 1;
    }
}

=head2 pushback($data)

Put data back into the socket.  Data will returned next time you
read().  Can be used if you find out that you have read too much.

=cut

sub pushback
{
    substr(shift->{'buffer'}, 0, 0) = shift;
}

=head2 write($data)

Write data to socket

=cut

sub write
{
    my $self = shift;
    LWP::Debug::trace('()');
    # XXX I guess should we time these out too?
    LWP::Debug::conns(">>>$_[0]<<<");
    $socket = $self->{'socket'};
    syswrite($socket, $_[0], length $_[0]);
}



#####################################################################
#
# Private methods
#

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
    if ($host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
        # numeric IP address
        $addr[0] = [$1, $2, $3, $4];
    } else {
        # hostname
        LWP::Debug::debugl("resolving host '$host'...");
        (undef,undef,undef,undef,@addr) = gethostbyname($host);
	return undef unless @addr;
	for (@addr) {
	    $_ = [ unpack('C4', $_) ];
	    LWP::Debug::debugl("   ..." . join(".", @$_));
	}
    }
    if (wantarray) {
	map(Socket::sockaddr_in(PF_INET, $port, @$_), @addr);
    } else {
	Socket::sockaddr_in(PF_INET, $port, @{$addr[0]});
    }
}


# Borrowed from POSIX.pm
# It should actually be in FileHandle.pm,
# so we could use it from there.

$gensym = 'SOCKET000';

sub _gensym
{
    'LWP::Socket::' . $gensym++;
}

sub _ungensym
{
    local($x) = shift;
    $x =~ s/.*:://;             # lose package name
    delete $LWP::Socket::{$x};  # delete from package symbol table
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
print "Socket.pm $LWP::Socket::VERSION ok\n";

sub chargen
{
    my $socket = new LWP::Socket;
    $socket->connect('localhost', 19); # chargen
    $socket->readUntil('A', \$buffer, 8);

    die 'Read Error' unless $buffer eq ' !"#$%&\'()*+,-./0123456789:;<=>?@';
    $socket->readUntil('Z', \$buffer, 8);
    die 'Read Error' unless $buffer eq 'BCDEFGHIJKLMNOPQRSTUVWXY';
}

sub echo
{
    $socket = new LWP::Socket;
    $socket->connect('localhost', 7); # echo
    $quote = 'I dunno, I dream in Perl sometimes...'; 
    #--Larry Wall in  <8538@jpl-devvax.JPL.NASA.GOV>
    $socket->write("$quote\n");
    $socket->readUntil("\n", \$buffer);
    die 'Read Error' unless $buffer eq $quote;
}


1;
