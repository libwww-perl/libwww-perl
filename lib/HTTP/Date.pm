#!/usr/local/bin/perl -w
#
# $Id: Date.pm,v 1.4 1995/07/13 14:55:49 aas Exp $
#
package LWP::Date;

=head1 NAME

time2str, str2time - date conversion routines

=head1 SYNOPSIS

 use LWP::Date;

 $stringGMT = time2str(time);   # Format as GMT time
 $mtime = str2time($stringGMT); # convert ascii date to machine time
 
=head1 DESCRIPTION

The C<time2str()> function converts a machine time to a string,
and the C<str2time()> function converts a string to machine time.
C<str2time()> returns undef if the format is unrecognised.

C<time2str()> returns the format defined by the HTTP/1.0 specification
to be the fixed length subset of the format defined by RFC 1123
(an update to RFC 822), represented in Universal Time (GMT):

 Thu, 03 Feb 1994 00:00:00 GMT

Running this module standalone executes a self-test.

=head1 SEE ALSO

See L<LWP> for a complete overview of libwww-perl5.

=head1 BUGS

C<str2time()> is far too lax; might get run-time warnings about
string/number mismatches when we get non-standard date strings. It
should use complete regular expressions for each format.

C<str2time()> could be taught to recognise elements in general
places, e.g. "1995 Wednesday, 7 July".

This whole module could probably be replaced by a standard Perl
module.

=cut

####################################################################

$VERSION = $VERSION = # shut up -w
    sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

require 5.001;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(time2str str2time);

use Time::Local;

@DoW = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

@MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);


####################################################################

=head1 FUNCTIONS

=head2 time2str($time)

Returns a fixed-length RFC 1123 date string in GMT 
for a given time such as returned by time().

=cut
sub time2str
{
    my $time = shift;

    my ($sec, $min, $hour, $mday, $mon, $year,
        $wday, $yday, $isdst) = gmtime($time);

    $year += 1900;
    
    $wday = substr($DoW[$wday],0,3);
    sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
            $wday, $mday, $MoY[$mon], $year, $hour, $min, $sec);
}


=head2 str2time($date)

Translate a date string to machine time (seconds since Epoch).

C<$date> can be any one of the following formats:

 "Wed, 09 Feb 1994 22:23:32 GMT"       -- proposed HTTP format
 "Thu Feb  3 17:03:55 GMT 1994"        -- ctime format
 "Tuesday, 08-Feb-94 14:15:29 GMT"     -- old rfc850 HTTP format
 "Tuesday, 08-Feb-1994 14:15:29 GMT"   -- broken rfc850 HTTP format

 "03/Feb/1994:17:03:55 -0700"   -- common logfile format
 "09 Feb 1994 22:23:32 GMT"     -- HTTP format (no weekday)
 "08-Feb-94 14:15:29 GMT"       -- rfc850 format (no weekday)
 "08-Feb-1994 14:15:29 GMT"     -- broken rfc850 format (no weekday)

 "08-Feb-94"     -- old rfc850 HTTP format    (no weekday, no time)
 "08-Feb-1994"   -- broken rfc850 HTTP format (no weekday, no time)
 "09 Feb 1994"   -- proposed new HTTP format  (no weekday, no time)
 "03/Feb/1994"   -- common logfile format     (no time, no offset)

Can only deal with > 1970 and < 2038. Returns undef on error.

=cut

sub str2time
{
    my($date) = shift;

    # Split date string
    my(@w) = split(' ', $date);

    # Remove useless weekday, if it exists
    if ($w[0] =~ /^\D/) { shift(@w); }

    if (!$w[0]) { return undef; }

    my($day, $mn, $yr, $hr, $min, $sec, $adate, $atime);
    my($offset) = 0;

    # Check which format
    if ($w[0] =~ /^\D/)   # Must be ctime (Feb  3 17:03:55 GMT 1994)
    {
        $mn    = shift(@w);
        $day   = shift(@w);
        $atime = shift(@w);
        shift(@w);
        $yr    = shift(@w);
    }
    elsif ($w[0] =~ m#/#) 
    {   # Must be common logfile (03/Feb/1994:17:03:55 -0700)
        ($adate, $atime) = split(/:/, $w[0], 2);
        ($day, $mn, $yr) = split(/\//, $adate);
        shift(@w);
        if ( defined $w[0] and $w[0] =~ m#^([+-])(\d\d)(\d\d)$# )
        {
            $offset = (3600 * $2) + (60 * $3);
            if ($1 eq '+') { $offset *= -1; }
        }
    }
    elsif ($w[0] =~ /-/)  # Must be rfc850 (08-Feb-94 ...)
    {
        ($day, $mn, $yr) = split(/-/, $w[0]);
        shift(@w);
        $atime = $w[0];
    }
    else                  # Must be rfc822 (09 Feb 1994 ...)
    {
        $day   = shift(@w);
        $mn    = shift(@w);
        $yr    = shift(@w);
        $atime = shift(@w);
    }
    if ($atime)
    {
        ($hr, $min, $sec) = split(/:/, $atime);
    }
    else
    {
        $hr = $min = $sec = 0;
    }

    if (!$mn || ($yr !~ /\d+/))     { return undef; }
    if (($yr > 99) && ($yr < 1970)) { return undef; }
    # Epoch started in 1970

    if ($yr < 70)    { $yr += 100;  }
    if ($yr >= 1900) { $yr -= 1900; }
    if ($yr >= 138)  { return undef; }
    # Epoch counter maxes out in year 2038, assuming "time_t" is 32 bit

    # Translate month name to number
    my $mon = _mon2num($mn);
    return undef unless defined $mon;

    # Translate to seconds since Epoch
    return (timegm($sec, $min, $hr, $day, $mon, $yr) + $offset);
}


# _mon2num($month)
#
# Given a three-letter abbreviation for a month,
# return monthnumber (Jan == 0), or undef on error
#
sub _mon2num {
    my $mon = shift;
    my $i = 0;
    for(@MoY) {
        return $i if (/^$mon$/i);
        $i++;
    }
    return undef;
}


####################################################################
#
# S E L F   T E S T   S E C T I O N
#
#####################################################################
#
# If we're not use'd or require'd execute self-test.
# Handy for regression testing and as a quick reference :)
#
# Test is kept behind __END__ so it doesn't take uptime
# and memory  unless explicitly required. If you're working
# on the code you might find it easier to comment out the
# eval and __END__ so that error line numbers make more sense.

package main;

eval join('',<DATA>) || die $@ unless caller();

1;

__END__

import LWP::Date @LWP::Date::EXPORT_OK;

# test str2time for supported dates
my(@tests) =
(
 'Thu Feb  3 00:00:00 GMT 1994',        # ctime format
 'Thu, 03 Feb 1994 00:00:00 GMT',       # proposed new HTTP format
 'Thursday, 03-Feb-94 00:00:00 GMT',    # old rfc850 HTTP format
 'Thursday, 03-Feb-1994 00:00:00 GMT',  # broken rfc850 HTTP format

 '03/Feb/1994:00:00:00 0000',   # common logfile format
 '03 Feb 1994 00:00:00 GMT',    # HTTP format (no weekday)
 '03-Feb-94 00:00:00 GMT',      # old rfc850 (no weekday)
 '03-Feb-1994 00:00:00 GMT',    # broken rfc850 (no weekday)

 '03-Feb-94',    # old rfc850 HTTP format    (no weekday, no time)
 '03-Feb-1994',  # broken rfc850 HTTP format (no weekday, no time)
 '03 Feb 1994',  # proposed new HTTP format  (no weekday, no time)
 '03/Feb/1994',  # common logfile format     (no time, no offset)
);

my $first = shift @tests;
my $time = str2time($first);

for (@tests) {
    die "str2time('$_') failed" unless str2time($_) == $time;
    print "ok: '$_'\n";
}

# test time2str
die "time2str failed"
    unless time2str($time,'GMT') eq 'Thu, 03 Feb 1994 00:00:00 GMT';

# try some out of bounds dates too.
for ('03-Feb-1969', '03-Feb-2039') {
    die "str2time('$_') failed" if defined str2time($_);
    print "ok: '$_'\n";
}
print "LWP::Date $LWP::Date::VERSION ok\n";
