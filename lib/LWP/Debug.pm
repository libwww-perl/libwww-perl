#!/usr/local/bin/perl -w
#
# $Id: Debug.pm,v 1.9 1996/02/26 20:14:25 aas Exp $
#
package LWP::Debug;

=head1 NAME

LWP::Debug - debug routines for the libwww-perl library

=head1 SYNOPSIS

 use LWP::Debug qw(level);

 level('+');
 level('-conns');

 # Used internally in the library
 LWP::Debug::trace('send()');
 LWP::Debug::debug('url ok');
 LWP::Debug::conns("read $n bytes: $data");

=head1 DESCRIPTION

LWP::Debug provides tracing facilities. The trace(),
debug() and conns() function log information at 
increasing levels of detail. Which level of detail is
actually printed is controlled with the C<level()>
function.

=head1 FUNCTIONS

=head2 level(...)

The C<level()> function controls the level of detail being
logged. Passing '+' or '-' indicates full and no logging
respectively. Inidividual levels can switched on and of by passing the
name of the level with a '+' or '-' prepended.  The levels are:

  trace   : trace function calls
  debug   : print debug messages
  conns   : show all data transfered over the connections

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

=cut

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(level trace debug conns);

use Carp ();

my @levels = qw(trace debug conns);
%current_level = ();


sub level
{
    for (@_) {
        if ($_ eq '+') {              # all on
            # switch on all levels
	    %current_level = map { $_ => 1 } @levels;
	} elsif ($_ eq '-') {           # all off
	    %current_level = ();
        } elsif (/^([-+])(\w+)$/) {
	    $current_level{$2} = $1 eq '+';
	} else {
	    Carp::croak("Illegal level format $_");
	}
    }
}

sub trace  { _log(@_) if $current_level{'trace'}; }
sub debug  { _log(@_) if $current_level{'debug'}; }
sub conns  { _log(@_) if $current_level{'conns'}; }

sub _log
{
    my $msg = shift;
    $msg .= "\n" unless $msg =~ /\n$/;  # ensure trailing "\n"

    my($package,$filename,$line,$sub) = caller(2);
    print STDERR "$sub: $msg";
}

1;
