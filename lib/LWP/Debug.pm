#!/usr/local/bin/perl -w
#
# $Id: Debug.pm,v 1.5 1995/07/14 00:15:03 aas Exp $
#
package LWP::Debug;

=head1 NAME

LWP::Debug - debug routines

=head1 SYNOPSIS

 use LWP::Debug;

 level('+');
 level('-conns');

 trace('send()');
 debug('url ok');
 conns("read $n bytes: $data");

 debugl("Resolving hostname '$host'");

 $SIG{'ALRM'} = 't';
 alarm(1);
 sub t {
     my $long = $LWP::Debug::longMsg();
     my $msg = 'Timeout';
     $msg .= ": $long" if defined $long;
     die $msg;
 }
    
=head1 DESCRIPTION

LWP::Debug provides tracing facilities. The C<trace>,
C<debug> and C<conns> function log information at 
increasing levels of detail. Which level of detail is
actually printed is controlled with the C<level()>
function.

=head1 SEE ALSO

See L<LWP> for a complete overview of libwww-perl5.

=cut

#####################################################################


require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(level trace conns debug debugl);

# debuglevel may have been set before use/require
# can be set any combination of the bitmasks below

my $debuglevel = 0;

my $bit_trace  = 1;      # function calls
my $bit_conns  = 2;      # connection
my $bit_debug  = 4;      # debug messages

%levels = (
           'trace' => $bit_trace,
           'conns' => $bit_conns,
           'debug' => $bit_debug,
           );

# timeout message, stored by _longMsg()
$timeoutMessage = undef;

#####################################################################

=head1 FUNCTIONS

=head2 trace($msg)

The C<trace()> function is used for tracing function 
calls. The package and calling subroutine name is
printed along with the passed argument. This should
be called at the start of every major function.

=head2 debug($msg)

The C<debug()> function is used for high-granularity
reporting of state in functions.

=head2 conns($msg)

The C<conns()> function is used to show data being
transferred over the connections. This may generate
considerable output.

=head2 debugl($msg)

The C<debugl> function is meant for operations which
take long time; The message is processed by C<debug()>,
and stored for later use by for example an SIGALRM
signal handler. 

=cut

sub trace  { _log($bit_trace, @_); }
sub conns  { _log($bit_conns, @_); }
sub debug  { _log($bit_debug, @_); }
sub debugl { _log($bit_debug, @_);
             _longMsg(@_);
           }

=head2 level(...)

The C<level()> function controls the level of
detail being logged. Passing '+' or '-' indicates
full and no logging respectively. Inidividual 
levels can switched on and of by passing the name
of the level with a '+' or '-' prepended.

=cut

sub level
{
    my (@levels) = @_;
    my $level; 
    for $level (@levels) {
        if ($level eq '+') {        # all on
            # switch on all levels
            my($k, $v);
            while(($k, $v) = each %levels) {
                $debuglevel |= $v;
            }
        }
        elsif ($level eq '-') {     # all off
            $debuglevel = 0;
        }
        elsif ($level =~ s/^\+//) {       # one on
            $debuglevel |= $levels{$level};
        }
        elsif ($level =~ s/^\-//) {        # one off
            $debuglevel &= ~ $levels{$level};
        }
    }
}

=head2 longMsg($msg)

Retrieve message set by debugl()

=cut
sub longMsg
{
    $LWP::Debug::timeoutMessage;
}

#####################################################################

# Internal Functions

# _log($trace, $msg)
#
# print message on STDERR if debuging is switched on
#
sub _log
{
    my($trace, $msg) = @_;

    # make sure message have got one trailing newline

    $msg =~ s/(?:\n)?$/\n/;

    my($package,$filename,$line,$sub) = caller(2);

    if ($trace & $debuglevel) {
        print STDERR "$sub: $msg";
    }
}

# _longMsg($msg)
#
# Store message in a variable for later reference.
# This is intended for long operations
# which are likely to be timed out.
#
sub _longMsg
{
    my $msg = shift;

    $LWP::Debug::timeoutMessage = $msg;
}

#####################################################################

1;
