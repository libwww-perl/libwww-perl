#!/local/bin/perl -w

# $Id: lwp-mirror.PL,v 1.1 1995/07/11 22:34:55 aas Exp $
#
# Simple mirror utility using LWP

use lib '..';
use LWP;
use URI::URL;
use Getopt::Std;

#use LWP::Debug;
#LWP::Debug::level('+trace');

$0 =~ s,.*/,,;  # use basename only

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

$ua = new LWP::UserAgent;

$opt_h = undef;  # print usage
$opt_v = undef;  # print version
$opt_b = undef;  # base url
$opt_t = undef;  # timeout
$opt_i = undef;  # if-modified-since

unless (getopts("hvb:t:i:")) {
    usage();
}

if ($opt_v) {
    die <<"EOT";
This is LWP $0 version $VERSION

Copyright (C) 1995 Gisle Aas. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
EOT
}

$file = shift or usage();
$url  = shift or usage();
usage() if $opt_h or @ARGV;

if (defined $opt_t) {
    $opt_t =~ /^(\d+)([smh])?/;
    die "$0: Illegal timeout value!\n" unless defined $1;
    $timeout = $1;
    $timeout *= 60   if ($2 eq "m");
    $timeout *= 3600 if ($2 eq "h");
    print "Timeout $timeout seconds\n";
    $ua->timeout($timeout);
}

if (defined $opt_i) {
    $time = str2time($opt_i);
    die "$0: Illegal time syntax for -i option\n"
	unless defined $time;
    $opt_i = time2str($time);
    die "$=: XXX no way to force the If-Modified-Header, Sorry\n";
}


$url = new URI::URL $url, $opt_b;

$response = $ua->mirror($url, $file);

if ($response->code == 304) {
    print STDERR "$0: $file was up to date\n"
} elsif (!$response->isSuccess) {
    print STDERR $response->errorAsHTML;
    exit 1;
}
exit;


sub usage
{
    die <<"EOT";
Usage: $0 [-options] <file> <url>
    -v           print version number of program
    -b <base>    Use the specified URL as base
    -t <timeout> Set timeout value
    -i <time>    Force value of If-Modified-Since header
EOT
}
