# $Id: Date.pm,v 1.11 1996/02/05 17:57:23 aas Exp $
#
package HTTP::Date;

=head1 NAME

time2str, str2time - date conversion routines

=head1 SYNOPSIS

 use HTTP::Date;

 $stringGMT = time2str(time);   # Format as GMT ascii time
 $time = str2time($stringGMT);  # convert ascii date to machine time

=head1 DESCRIPTION

The time2str() function converts a machine time (seconds since epoch)
to a string.  If the function is called without an argument it will
use the current time.

The string returned is in the format defined by the HTTP/1.0
specification.  This is a fixed length subset of the format defined by
RFC 1123, represented in Universal Time (GMT).  An example of this
format is:

   Thu, 03 Feb 1994 00:00:00 GMT

The str2time() function converts a string to machine time and the
function is able to parse the following formats:

 "Wed, 09 Feb 1994 22:23:32 GMT"       -- proposed HTTP format
 "Thu Feb  3 17:03:55 GMT 1994"        -- ctime() format
 'Thu Feb  3 00:00:00 1994',           -- ANSI C asctime() format
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

The parser ignores leading or trailing whitespace.  It also accepts
that the seconds are missing and that the month is numerical.

The str2time() function returns undef if the format is unrecognised,
or the year is not between 1970 and 2038.

=cut


$VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

require 5.001;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(time2str str2time);

require Time::Local;

@DoW = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
@MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
# Build %MoY hash
my $i = 0;
foreach(@MoY) {
   $MoY{lc $_} = $i++;
}


sub time2str
{
   my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime(shift || time);
   sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
	   substr($DoW[$wday],0,3),
	   $mday, $MoY[$mon], $year+1900,
	   $hour, $min, $sec);
}


sub str2time
{
   local($_) = shift;
   return undef unless defined;

   # Remove useless weekday, if it exists
   s/^\s*(?:sun|mon|tue|wed|thu|fri|sat)\w*,?\s*//i;

   my($day, $mon, $yr, $hr, $min, $sec, $tz);
   my $offset = 0;  # used when compensating for timezone

 PARSEDATE: {
      # First we handle the ctime and asctime format since they are different
      ($mon, $day, $hr, $min, $sec, $yr) =
	/^\s*             # allow intial whitespace
	 (\w+)            # month       
	    \s+
         (\d+)            # day
            \s+
         (\d+):(\d+)      # hour:min
         (?::(\d+))?      # optional seconds
            \s+
         (?:GMT\s+)?      # optional GMT timezone
         (\d+)            # year
            \s*$          # allow traling whitespace
	/x
	  and last PARSEDATE;

      # Then we are able to check for all the other formats with this regexp
      ($day,$mon,$yr,$hr,$min,$sec,$tz) =
	/^\s*
	 (\d+)                 # day
            (?:\s+|[-\/])
         (\w+)                 # month
            (?:\s+|[-\/])
         (\d+)                 # year
	 (?:
               (?:\s+|:)       # separator before clock
            (\d+):(\d+)        # hour:min
	    (?::(\d+))?        # optional seconds
         )?                    # optional clock
            \s*
	 ([-+]?\d{4}|GMT|gmt)? # timezone
	    \s*$
	/x
	  and last PARSEDATE;

      # If it is not recognized by now we give up
      return undef;
   }

   # First let's compensate for the timezone
   if (defined $tz && $tz =~ /^([-+])?(\d\d)(\d\d)$/) {
      $offset = 3600 * $2 + 60 * $3;
      $offset *= -1 if $1 ne '-';
   }

   # Then we check if the year is acceptable
   return undef if $yr > 99 && $yr < 1970;  # Epoch started in 1970
   # Epoch counter maxes out in year 2038, assuming "time_t" is 32 bit
   return undef if $yr > 2038;

   $yr += 100 if $yr < 70;
   $yr -= 1900 if $yr >= 1900;

   # Translate month name to number
   if ($mon =~ /^\d+$/) {
     # numeric month
     return undef if $mon < 1 || $mon > 12;
     $mon--; 
   } else {
     return undef unless exists $MoY{lc $mon};
     $mon = $MoY{lc $mon};
   }

   # Check the day
   return undef if $day < 1 || $day > 31;

   # Make sure things are defined
   for ($sec, $min, $hr) {  $_ = 0 unless defined   }

   # Translate to seconds since Epoch
   return Time::Local::timegm($sec, $min, $hr, $day, $mon, $yr) + $offset;
}

1;
