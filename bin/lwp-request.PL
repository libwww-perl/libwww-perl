#!/local/bin/perl -w

# $Id: lwp-request.PL,v 1.1 1995/07/11 22:34:54 aas Exp $
#
# Simple user agent using LWP library.  It's interface is based on the
# libwww-perl-0.40 program with the same name.

use lib '..';
use LWP;
use LWP::Date qw(str2time time2str);
use URI::URL;
use Getopt::Std;

#use LWP::Debug;
#LWP::Debug::level('+trace');

$0 =~ s,.*/,,;  # use basename only

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

# "N" = Allowed without content in request
# "C" = Allowed and with content in request
%allowed_methods = (
    GET        => "N",   
    HEAD       => "N",
    POST       => "C",   
    PUT        => "C",
    DELETE     => "N",   
    LINK       => "N",
    UNLINK     => "N",
    CHECKIN    => "C",
    CHECKOUT   => "N",
    SHOWMETHOD => "N",
);


$ua = new LWP::UserAgent;

$opt_h = undef;  # print usage
$opt_v = undef;  # print version
$opt_b = undef;  # base url
$opt_t = undef;  # timeout
$opt_d = undef;  # don't display content
$opt_e = undef;  # display response headers (default for HEAD)
$opt_E = undef;  # display headers on both request and response
$opt_i = undef;  # if-modified-since
$opt_c = undef;  # content type for POST
$opt_m = undef;  # set method

unless (getopts("hvedb:t:i:c:m:")) {
    usage();
}
usage() if $opt_h || !@ARGV;

if ($opt_v) {
    die <<"EOT";
This is LWP $0 version $VERSION

Copyright (C) 1995 Gisle Aas. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
EOT
}

$method = uc ($opt_m || $0 || "GET");

unless (defined $allowed_methods{$method}) {
    die "$0: $method is not an allowed method\n";
}

if ($method eq "HEAD") {
    $opt_e = 1 unless $opt_d;
    $opt_d = 1;
}

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
}

$content = undef;
if ($allowed_methods{$method} eq "C") {
    # This request needs some content
    unless (defined $opt_c) {
	# set default content type
	$opt_c = ($method eq "POST") ?
	      "application/x-www-form-urlencoded"
	    : "text/plain";
    } else {
	die "$0: Illegal Content-type format\n"
	    unless $opt_c =~ m,^[\w\-]+/[\w\-]+$,
    }
    print "Please enter content ($opt_c) to be ${method}ed:\n"
	if -t;
    $content = join("", <STDIN>);
} else {
    die "$0: Can't set Content-type for $method requests\n"
	if defined $opt_c;
}


$errors = 0;
while ($url = shift) {
    $url = new URI::URL $url, $opt_b;
    print "$method $url\n";

    $request = new LWP::Request($method, $url);

    $request->header('If-Modified-Since', $opt_i) if defined $opt_i;
    $request->header('User-Agent', "LWP $0/$VERSION");
    if ($opt_c) { # will always be set for request that wants content
	$request->header('Content-type', $opt_c);
	$request->content($content);
    }

    if ($opt_E) {
	print STDERR $request->headers->as_string;
	print STDERR "----\n";
    }


    $response = $ua->request($request);

    if ($opt_e) {
	# Display headers
	print STDERR $response->headers->as_string;
    }

    if ($response->isSuccess) {
	print $response->content unless $opt_d;
    } else {
	print STDERR "ERROR\n";
	print STDERR $response->errorAsHTML;
	$errors++;
    }
}

exit $errors;



sub usage
{
    die <<"EOT";
Usage: $0 [-options] <url>...
    -e Display headers
    -q Don't display content
    -b <base> Use the specified URL as base
    -t <timeout> use this timeout value
    -i <time> Add the If-Modified-Since header
    -c <conttype> use this content-type for POST, PUT, CHECKIN
    -m <method>
EOT
}
