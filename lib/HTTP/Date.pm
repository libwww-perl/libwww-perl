package HTTP::Date;  # $Date: 1999/04/23 13:07:11 $

$VERSION = sprintf("%d.%02d", q$Revision: 1.30 $ =~ /(\d+)\.(\d+)/);

require 5.002;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(time2str str2time);
@EXPORT_OK = qw(time2iso time2isoz);

use strict;
use Time::Local ();

use vars qw(@DoW @MoY %MoY);
@DoW = qw(Sun Mon Tue Wed Thu Fri Sat);
@MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@MoY{map lc, @MoY} = (1..12);

my %zulu_zone = (gmt => 0, utc => 0, ut => 0, z => 0);


sub time2str (;$)
{
    my $time = shift;
    $time = time unless defined $time;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
    sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
	    $DoW[$wday],
	    $mday, $MoY[$mon], $year+1900,
	    $hour, $min, $sec);
}


sub str2time ($;$)
{
    my @d = &str2date;
    return unless @d;
    $d[0] -= 1900;  # year
    $d[1]--;        # month

    # timelocal() seems to go into an infinite loop if it is given out
    # of range parameters.  Let's check the year at least.
    # Epoch counter maxes out in year 2038, assuming "time_t" is 32 bit
    return if $d[0] > 138;
    return if $d[0] <  70;  # 1970 is Unix epoch

    my $mktime_func = pop(@d) ? \&Time::Local::timegm
	                      : \&Time::Local::timelocal;
    eval { &$mktime_func(reverse @d) };
}


sub str2date ($;$)
{
    local($_) = shift;
    return unless defined;
    my $default_zone = shift;

    s/^\s+//;  # kill leading space
    s/^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)\w*,?\s*//i; # Useless weekday

    my($day, $mon, $yr, $hr, $min, $sec, $tz, $aorp);

  PARSEDATE: {
      # Then we are able to check for most of the formats with this regexp
      ($day,$mon,$yr,$hr,$min,$sec,$tz) =
	/^
	 (\d\d?)               # day
	    (?:\s+|[-\/])
	 (\w+)                 # month
	    (?:\s+|[-\/])
	 (\d+)                 # year
	 (?:
	       (?:\s+|:)       # separator before clock
	    (\d\d?):(\d\d)     # hour:min
	    (?::(\d\d))?       # optional seconds
	 )?                    # optional clock
	    \s*
	 ([-+]?\d{2,4}|GMT|gmt)? # timezone
	    \s*$
	/x
	  and last PARSEDATE;

      # Try the ctime and asctime format
      ($mon, $day, $hr, $min, $sec, $tz, $yr) =
	/^
	 (\w{1,3})             # month
	    \s+
	 (\d\d?)               # day
	    \s+
	 (\d\d?):(\d\d)        # hour:min
	 (?::(\d\d))?          # optional seconds
	    \s+
	 (?:(GMT|gmt)\s+)?     # optional GMT timezone
	 (\d+)                 # year
	    \s*$               # allow trailing whitespace
	/x
	  and last PARSEDATE;

      # Then the Unix 'ls -l' date format
      ($mon, $day, $yr, $hr, $min, $sec) =
	/^
	 (\w{3})               # month
	    \s+
	 (\d\d?)               # day
	    \s+
	 (?:
	    (\d\d\d\d) |       # year
	    (\d{1,2}):(\d{2})  # hour:min
            (?::(\d\d))?       # optional seconds
	 )
	 \s*$
       /x
	 and last PARSEDATE;

      # ISO 8601 format '1996-02-29 12:00:00 -0100' and variants
      ($yr, $mon, $day, $hr, $min, $sec, $tz) =
	/^
	  (\d{4})              # year
	     [-\/]?
	  (\d\d?)              # numerical month
	     [-\/]?
	  (\d\d?)              # day
	 (?:
	       (?:\s+|:|T|-)   # separator before clock
	    (\d\d?):?(\d\d)    # hour:min
	    (?::?(\d\d))?      # optional seconds
	 )?                    # optional clock
	    \s*
	 ([-+]?\d\d?:?(:?\d\d)?
	  |Z|z)?               # timezone  (Z is "zero meridian", i.e. GMT)
	    \s*$
	/x
	  and last PARSEDATE;

      # Windows 'dir' 11-12-96  03:52PM
      ($mon, $day, $yr, $hr, $min, $aorp) =
        /^
          (\d{2})                # numerical month
             -
          (\d{2})                # day
             -
          (\d{2})                # year
             \s+
          (\d\d?):(\d\d)([apAP][mM])  # hour:min AM or PM
             \s*$
        /x
          and last PARSEDATE;

      # If it is not recognized by now we give up
      return;
    }

    # Translate month name to number
    if ($mon =~ /^\d+$/) {
	# numeric month
	return if $mon < 1 || $mon > 12;
    } else {
	$mon = $MoY{lc $mon} || return;
    }

    # If the year is missing, we assume some date before the current,
    # because of the formats we support such dates are mostly present
    # on "ls -l" listings.
    unless (defined $yr) {
	my($cur_mon, $yr) = (localtime)[4, 5];
	$yr += 1900;
	$yr-- if $mon > $cur_mon;
    }

    # Then we check if the year is acceptable
    if (length($yr) < 3) {
	# Find "obvious" year
	my $cur_yr = (localtime)[5] + 1900;
	my $m = $cur_yr % 100;
	my $tmp = $yr;

	$yr += $cur_yr - $m;
	$m -= $tmp;
	$yr += ($m > 0) ? 100 : -100
	    if abs($m) > 50;
    }

    # Make sure clock elements are defined
    for ($sec, $min, $hr) {  $_ = 0 unless defined   }

    # Compensate for AM/PM
    if ($aorp) {
	$aorp = uc $aorp;
	$hr = 0 if $hr == 12 && $aorp eq 'AM';
	$hr += 12 if $aorp eq 'PM' && $hr != 12;
    }

    my $gmt;
    $tz = shift unless defined $tz;
    if (defined $tz) {
	$gmt++;

	my $offset;
	if (exists $zulu_zone{lc $tz}) {
	    # ok
	    $offset = 0;
	} elsif ($tz =~ /^([-+])?(\d\d?):?(\d\d)?$/) {
	    $offset = 3600 * $2;
	    $offset += 60 * $3 if $3;
	    $offset *= -1 if $1 && $1 ne '-';
	} else {
	    require Time::Zone;
	    die;
	    $offset = Time::Zone::tz_offset($tz);
	}
	if ($offset) {
	    die "NYI";
	    
	}
    }
	
    wantarray ? ($yr, $mon, $day, $hr, $min, $sec, $gmt)
	      : sprintf("%04d-%02d-%02d %02d:%02d:%02d%s",
			$yr, $mon, $day, $hr, $min, $sec, $gmt?"Z":"");
}

sub time2iso (;$)
{
    my $time = shift;
    $time = time unless defined $time;
    my($sec,$min,$hour,$mday,$mon,$year) = localtime($time);
    sprintf("%04d-%02d-%02d %02d:%02d:%02d",
	    $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

sub time2isoz (;$)
{
    my $time = shift;
    $time = time unless defined $time;
    my($sec,$min,$hour,$mday,$mon,$year) = gmtime($time);
    sprintf("%04d-%02d-%02d %02d:%02d:%02dZ",
            $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

1;

__END__

=head1 NAME

HTTP::Date - date conversion routines

=head1 SYNOPSIS

 use HTTP::Date;

 $string = time2str($time);    # Format as GMT ASCII time
 $time = str2time($string);    # convert ASCII date to machine time

=head1 DESCRIPTION

This module provides two functions that deal with the HTTP date
format.  The following functions are provided:

=over 4

=item time2str([$time])

The time2str() function converts a machine time (seconds since epoch)
to a string.  If the function is called without an argument, it will
use the current time.

The string returned is in the format defined by the HTTP
specification.  This is a fixed length subset of the format defined by
RFC 1123, represented in Universal Time (GMT).  An example of this
format is:

   Thu, 03 Feb 1994 17:09:00 GMT

=item str2time($str [, $zone])

The str2time() function converts a string to machine time.  It returns
C<undef> if the format is unrecognized, or the year is not between 1970
and 2038.  The function is able to parse the following formats:

 "Wed, 09 Feb 1994 22:23:32 GMT"       -- HTTP format
 "Thu Feb  3 17:03:55 GMT 1994"        -- ctime(3) format
 "Thu Feb  3 00:00:00 1994",           -- ANSI C asctime() format
 "Tuesday, 08-Feb-94 14:15:29 GMT"     -- old rfc850 HTTP format
 "Tuesday, 08-Feb-1994 14:15:29 GMT"   -- broken rfc850 HTTP format

 "03/Feb/1994:17:03:55 -0700"   -- common logfile format
 "09 Feb 1994 22:23:32 GMT"     -- HTTP format (no weekday)
 "08-Feb-94 14:15:29 GMT"       -- rfc850 format (no weekday)
 "08-Feb-1994 14:15:29 GMT"     -- broken rfc850 format (no weekday)

 "1994-02-03 14:15:29 -0100"    -- ISO 8601 format
 "1994-02-03 14:15:29"          -- zone is optional
 "1994-02-03"                   -- only date
 "1994-02-03T14:15:29"          -- Use T as separator
 "19940203T141529Z"             -- ISO 8601 compact format
 "19940203"                     -- only date

 "08-Feb-94"         -- old rfc850 HTTP format    (no weekday, no time)
 "08-Feb-1994"       -- broken rfc850 HTTP format (no weekday, no time)
 "09 Feb 1994"       -- proposed new HTTP format  (no weekday, no time)
 "03/Feb/1994"       -- common logfile format     (no time, no offset)

 "Feb  3  1994"      -- Unix 'ls -l' format
 "Feb  3 17:03"      -- Unix 'ls -l' format

 "11-15-96  03:52PM" -- Windows 'dir' format

The parser ignores leading and trailing whitespace.  It also allow the
seconds to be missing and the month to be numerical in most formats.

The str2time() function takes an optional second argument that
specifies the default time zone to use when converting the date.  This
zone specification should be numerical (like "-0800" or "+0100") or
"GMT".  This parameter is ignored if the zone is specified in the date
string itself.  It this parameter is missing, and the date string
format does not contain any zone specification then the local time
zone is assumed.

If the year is missing, then we assume that the date is the first
matching date I<before> current time.

=back

=head1 BUGS

The str2time() function has been told how to parse far too many
formats.  This makes the module name misleading. To be sure it is
really misleading you can also import the time2iso() and time2isoz()
functions.  They work like time2str() but produce ISO-8601 formated
strings (YYYY-MM-DD hh:mm:ss).

=head1 COPYRIGHT

Copyright 1995-1999, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
