#!/local/bin/perl -w
#
# $Id: Socket.pm,v 1.6 1995/08/03 07:25:12 aas Exp $

package LWP::Socket;

=head1 NAME

LWP::Socket - TCP/IP socket interface

=head1 SYNOPSIS

 $socket = new LWP::Socket;
 $socket->open('localhost', 7); # echo
 $quote = 'I dunno, I dream in Perl sometimes...';
 $socket->write("$quote\n");
 $socket->readUntil("\n", \$buffer);
 $socket->close;

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

$VERSION = $VERSION = # shut up -w
    sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

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
        'buffer' => undef,
        'size' => 4096,
    }, $class;

    return $self;
}

sub DESTROY
{
    my($self) = @_;
    $self->close;
}


=head2 open($host, $port)

Connect the socket to given host and port

=cut

sub open
{
    my($self, $host, $port) = @_;

    LWP::Debug::trace("($host, $port)");

    $self->{'host'} = $host;
    $self->{'port'} = $port;

    my $socket = $self->{'socket'};

    my $addr = $self->_getaddress($host, $port);

    LWP::Debug::debugl("Connecting to host '$host' on port '$port'...");

    connect($socket, $addr) or die 
        "Couldn't connect to host '$host' on port '$port': $!\n";
}

=head2 readUntil($delim, $bufferref, $size)

Reads data from the socket, up to a delimiter specified by a regular
expression.  If $delim is undefined all data is read.  If $size is
defined, data will be read in chunks of $size bytes.

Note that $delim is discarded.

Uses select() to allow timeouts.  Uses sysread() and internal
buffering for safety.

=cut

sub readUntil
{
    my ($self, $delim, $bufferref, $size, $timeout) = @_;

    my($beforeref) = \$self->{'buffer'};
    my($socket) = $self->{'socket'};
    my($size) = $self->{'size'};

    LWP::Debug::trace('(...)');

    my $totalbuffer = '';       # result so far
    $totalbuffer = $self->{'buffer'} if defined $self->{'buffer'};
    $self->{'buffer'} = '';

    my $read = -1;
    while(!(defined $delim and $delim and $totalbuffer =~ /$delim/)
          and $read != 0) {

        my ($rin, $rout, $win, $wout, $ein, $eout) = 
            ('', '', '', '', '', '');
        vec($rin,fileno($socket),1) = 1;

        LWP::Debug::debug('selecting');

        my($nfound,$timeleft) =
            select($rout=$rin, $wout=$win, $eout=$ein, $timeout);
        if ($nfound == 0) {
            # die "Timeout";
            return 0;
        } elsif ($nfound < 0) {
            die "Select failed: $!";
        } else {
            LWP::Debug::debug('reading');

            my $buffer = '';
            $read = sysread($socket, $buffer, $size);
            $totalbuffer .= $buffer if defined $buffer;

            LWP::Debug::conns("Read $read bytes: >>>$buffer<<<");
        }
        last if (!defined $delim and $read == 0);
    }

    if (defined $delim) {
        ($$bufferref, $self->{'buffer'}) = split($delim, $totalbuffer, 2);
    } else {
        $$bufferref = $totalbuffer;
    }

    LWP::Debug::debug("\nResult: " .
                      (defined $$bufferref ? ">>>$$bufferref<<<" : 'undef') .
                      "\nBuffered: " . 
                      (defined $self->{'buffer'} ?
                       ">>>$self->{'buffer'}<<<" : 'undef') );

    1;
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


=head2 close()

Close the connection

=cut

sub close
{
    my($self) = @_;
    LWP::Debug::trace('()');

    my $socket = $self->{'socket'};
    if (defined $socket) {
        close($socket);
        _ungensym($socket);
        delete $self->{'socket'};
    }
}


#####################################################################
#
# Private methods
#

=head2 _getaddress($h, $p)

Return address to connect a socket to, given a host and port. If host
or port are omitted the internal values are used.

=cut

# TODO: in array context return all addresses
# for the host, so we can try them in turn.

sub _getaddress
{
    my($self, $h, $p) = @_;

    LWP::Debug::trace('(' . (defined $h ? $h : 'undef') .
                      ', '. (defined $p ? $p : 'undef') . ')');

    my($host) = (defined $h ? $h : $self->{'host'});
    my($port) = (defined $p ? $p : $self->{'port'});

    my($thataddr);

    if ($host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
        # just IP address
        $thataddr = pack('c4', $1, $2, $3, $4);
    } else {
        # hostname
        LWP::Debug::debugl("resolving host '$host'...");

        $thataddr = (gethostbyname($host))[4] or
            die "Cannot find host '$host'\n";
    }
    my $sockaddr = 'S n a4 x8';
    return pack($sockaddr, PF_INET, $port, $thataddr);
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

&chargen;
&echo;
print "Socket.pm $LWP::Socket::VERSION ok\n";

sub chargen
{
    my $socket = new LWP::Socket;
    $socket->open('localhost', 19); # chargen
    $socket->readUntil('A', \$buffer, 8);

    die 'Read Error' unless $buffer eq ' !"#$%&\'()*+,-./0123456789:;<=>?@';
    $socket->readUntil('Z', \$buffer, 8);
    die 'Read Error' unless $buffer eq 'BCDEFGHIJKLMNOPQRSTUVWXY';

    $socket->close;
}

sub echo
{
    $socket = new LWP::Socket;
    $socket->open('localhost', 7); # echo
    $quote = 'I dunno, I dream in Perl sometimes...'; 
    #--Larry Wall in  <8538@jpl-devvax.JPL.NASA.GOV>
    $socket->write("$quote\n");
    $socket->readUntil("\n", \$buffer);
    die 'Read Error' unless $buffer eq $quote;
    $socket->close;
}


1;
