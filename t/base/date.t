use HTTP::Date;

print "1..26\n";

$no = 1;
sub ok {
   print "not " if $_[0];
   print "ok $no\n";
   $no++;
}

# test str2time for supported dates
my(@tests) =
(
 'Thu Feb  3 00:00:00 GMT 1994',        # ctime format
 'Thu Feb  3 00:00:00 1994',            # same as ctime, except no TZ

 'Thu, 03 Feb 1994 00:00:00 GMT',       # proposed new HTTP format
 'Thursday, 03-Feb-94 00:00:00 GMT',    # old rfc850 HTTP format
 'Thursday, 03-Feb-1994 00:00:00 GMT',  # broken rfc850 HTTP format

 '03/Feb/1994:00:00:00 0000',   # common logfile format
 '03/Feb/1994:01:00:00 +0100',  # common logfile format
 '02/Feb/1994:23:00:00 -0100',  # common logfile format

 '03 Feb 1994 00:00:00 GMT',    # HTTP format (no weekday)
 '03-Feb-94 00:00:00 GMT',      # old rfc850 (no weekday)
 '03-Feb-1994 00:00:00 GMT',    # broken rfc850 (no weekday)
 '03-Feb-1994 00:00 GMT',       # broken rfc850 (no weekday, no seconds)

 '03-Feb-94',    # old rfc850 HTTP format    (no weekday, no time)
 '03-Feb-1994',  # broken rfc850 HTTP format (no weekday, no time)
 '03 Feb 1994',  # proposed new HTTP format  (no weekday, no time)
 '03/Feb/1994',  # common logfile format     (no time, no offset)

 # A few tests with extra space at various places
 '  03/Feb/1994      ',
 '  03   Feb   1994  0:00  ',
);

my $time = 760233600;
for (@tests) {
    die "str2time('$_') failed" unless str2time($_) == $time;
    print "'$_'\n";
    ok;
}

# test time2str
die "time2str failed"
    unless time2str($time) eq 'Thu, 03 Feb 1994 00:00:00 GMT';

# try some out of bounds date and some garbage.
for ('03-Feb-1969', '03-Feb-2039',
     undef, '', 'Garbage', 
     'Mandag 16. September 1996',
     'Thu Feb  3 00:00:00 CET 1994',
     'Thu, 03 Feb 1994 00:00:00 CET',
    )
{
    die "str2time('$_') failed" if defined str2time($_);
    print defined($_) ? "'$_'\n" : "undef\n";
    ok;
}
print "HTTP::Date $HTTP::Date::VERSION tested ok\n";


