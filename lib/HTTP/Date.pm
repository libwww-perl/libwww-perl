# $Id: Date.pm,v 1.10 1995/08/27 22:31:39 aas Exp $
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
to a string, and the str2time() function converts a string to machine
time. 

The time2str() function returns a string in the format defined by the
HTTP/1.0 specification.  This is a fixed length subset of the format
defined by RFC 1123, represented in Universal Time (GMT), e.g:

 Thu, 03 Feb 1994 00:00:00 GMT

The str2time() function can parse the following formats:

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

The str2time() function returns undef if the format is unrecognised,
or the year is not between 1970 and 2038.

=head1 BUGS

C<str2time()> is far too lax; might get run-time warnings about
string/number mismatches when we get non-standard date strings. It
should use complete regular expressions for each format.

C<str2time()> could be taught to recognise elements in general
places, e.g. "1995 Wednesday, 7 July".

=cut


$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);
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
foreach(@MoY) { $MoY{$_} = $i++; }
undef($i);


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
        shift(@w) if @w > 1;
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
    my $mon = $MoY{$mn};
    return undef unless defined $mon;

    # Translate to seconds since Epoch
    return (Time::Local::timegm($sec, $min, $hr, $day, $mon, $yr) + $offset);
}

1;
