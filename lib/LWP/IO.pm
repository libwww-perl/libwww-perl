package LWP::IO;

# $Id: IO.pm,v 1.9 1997/04/05 12:38:04 aas Exp $

require LWP::Debug;
use AutoLoader ();
*AUTOLOAD = \&AutoLoader::AUTOLOAD;  # import the AUTOLOAD method

sub read;
sub write;

1;
__END__

=head1 NAME

LWP::IO - Low level I/O capability

=head1 SYNOPSIS

 use LWP::IO ();

=head1 DESCRIPTION

=head2 LWP::IO::read($fd, $data, $size, $offset, $timeout)

=head2 LWP::IO::write($fd, $data, $timeout)

These routines provide low level I/O with timeout capability for the
LWP library.  These routines will only be installed if they are not
already defined.  This fact can be used by programs that need to
override these functions.  Just provide replacement functions before
you require LWP. See also L<LWP::TkIO>.

=cut

sub read
{
    my $fd      = shift;
    # data is now $_[0]
    my $size    = $_[1];
    my $offset  = $_[2] || 0;
    my $timeout = $_[3];

    my $rin = '';
    vec($rin, fileno($fd), 1) = 1;
    my $err;
    my $nfound = select($rin, undef, $err = $rin, $timeout);
    if ($nfound == 0) {
	die "Timeout";
    } elsif ($nfound < 0) {
	die "Select failed: $!";
    } elsif ($err =~ /[^\0]/) {
	die "Exception while reading on socket handle";
    } else {
	my $n = sysread($fd, $_[0], $size, $offset);
	# Since so much data might pass here we cheat about debugging
	if ($LWP::Debug::current_level{'conns'}) {
	    LWP::Debug::debug("Read $n bytes");
	    LWP::Debug::conns($_[0]) if $n;
	}
	return $n;
    }
}


sub write
{
    my $fd = shift;
    my $timeout = $_[1];  # we don't want to copy data in $_[0]

    my $len = length $_[0];
    my $offset = 0;
    while ($offset < $len) {
	my $win = '';
	vec($win, fileno($fd), 1) = 1;
	my $err;
	my $nfound = select(undef, $win, $err = $win, $timeout);
	if ($nfound == 0) {
	    die "Timeout";
	} elsif ($nfound < 0) {
	    die "Select failed: $!";
	} elsif ($err =~ /[^\0]/) {
	    die "Exception while writing on socket handle";
	} else {
	    my $n = syswrite($fd, $_[0], $len-$offset, $offset);
	    return $bytes_written unless defined $n;

	    if ($LWP::Debug::current_level{'conns'}) {
		LWP::Debug::conns("Write $n bytes: '" .
				  substr($_[0], $offset, $n) .
				  "'");
	    }
	    $offset += $n;
	}
    }
    $offset;
}

1;
