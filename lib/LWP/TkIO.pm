package LWP::IO;

# $Id: TkIO.pm,v 1.4 1996/04/07 20:39:06 aas Exp $

require Tk;
require LWP::Debug;

=head1 NAME

LWP::TkIO - Tk I/O routines for the LWP library

=head1 SYNOPSIS

 use Tk;
 require LWP::TkIO;
 require LWP::UserAgent;

=head1 DESCRIPTION

This module provide replacement functions for the LWP::IO
functions. Require this module if you use Tk and want non exclusive IO
behaviour from LWP.  This does not allow LWP to run simultaneous
requests though.

See also L<LWP::IO>.

=cut


sub read
{
    my $fd = shift;
    my $dataRef = \$_[0];
    my $size    =  $_[1];
    my $offset  =  $_[2] || 0;
    my $timeout =  $_[3];

    my $doneFlag = 0;
    my $timeoutFlag = 0;
    my $n;

    Tk->fileevent($fd, 'readable',
		  sub {
		      $n = sysread($fd, $$dataRef, $size, $offset);
		      LWP::Debug::conns("Read $n bytes: '" .
					substr($$dataRef, $offset, $n) .
					"'") if defined $n;
		      $doneFlag = 1;
		  }
		 );
    my $timer = Tk->after($timeout*1000, sub {$timeoutFlag = 1;} );

    Tk::DoOneEvent(0) until ($doneFlag || $timeoutFlag);

    Tk->after(cancel => $timer);
    Tk->fileevent($fd, 'readable', ''); # no more callbacks
    die "Timeout" if $timeoutFlag;
    return $n;
}


sub write
{
    my $fd = shift;
    my $dataRef = \$_[0];
    my $timeout =  $_[1];

    my $len = length $$dataRef;

    return 0 unless $len;

    my $offset = 0;
    my $timeoutFlag = 0;
    my $doneFlag = 0;

    my $timeoutSub = sub { $timeoutFlag = 1; };
    my $timer;
    $timer = Tk->after($timeout*1000, $timeoutSub ) if $timeout;

    Tk->fileevent($fd, 'writable',
		  sub {
		      my $n = syswrite($fd, $$dataRef, $len-$offset, $offset);
		      if (!defined $n) {
			  $done = 1;
		      } else {
			  LWP::Debug::conns("Write $n bytes: '" .
					    substr($$dataRef, $offset, $n) .
					    "'");
			  $offset += $n;
			  $timer = Tk->after($timeout*1000, $timeoutSub )
			    if $timeout;
		      }
		  }
		 );

    Tk::DoOneEvent(0) until ($timeoutFlag || $doneFlag || $offset >= $len);

    Tk->fileevent($fd, 'writable', ''); # no more callbacks
    Tk->after(cancel => $timer) if $timeout;

    die "Timeout" if $timeoutFlag;
    $offset;
}

1;
