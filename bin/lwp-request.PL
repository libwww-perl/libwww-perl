#!/local/bin/perl -w

# $Id: lwp-request.PL,v 1.2 1995/07/13 14:10:54 aas Exp $
#
# Simple user agent using LWP library.  It's interface is based on the
# libwww-perl-0.40 program with the same name.

=head1 NAME

get - Simple WWW user agent

=head1 SYNOPSIS

 get [-eEdvh] [-b <base URL>] [-t <timeout>] [-i <if-modified-since>]
     [-c <content-type>] [-m method] <url>...

=head1 DESCRIPTION

This program can be used to send requests to WWW servers. The content
for POST, PUT and CHECKIN methods is read from stdin.  The content of
the response is printed on stdout.  Error messages are printed on
stderr.  The program returns a status value indicating the number of
URLs that failed.

The options are:

=over 3

=item -e

Print response headers to stderr.  This option is always on for HEAD requests.

=item -E

Print both request and response headers to stderr.

=item -d

Do not print the content.

=item -b <url>

This URL will be used as the base URL.  The base URL only takes effect
for relative URLs.

=item -t <timeout>

Set the timeout value for the requests.  The timeout is the amount of
time that the program will wait for a response from the remote server
before it fails.  The default unit for the timeout value is seconds.
You might append "m" to the timeout value to make it minutes.  The
default timeout is '3m', i.e. 3 minutes.

=item -i <time>

Set the If-Modified-Since header in the request. If I<time> it the
name of a file, use the modification timestamp for this file. If
I<time> is not a file, it is parsed as a literal date. Take a look at
L<LWP::Date> for recogniced formats.

=item -c <content-type>

Set the Content-Type for the request.  This option is only allowed for
requests that take a content, i.e. POST, PUT and CHECKIN.  The default
Content-Type for POST is C<application/x-www-form-urlencoded>.  The
default Content-type for the others are C<text/plain>.

=item -m <method>

Set which method to use for the request.  If this option is not used,
then the method is derived for the name of the program.

=item -v

Print the version of the program and quit.

=item -h

Print usage message and quit.

=back

Because this program is implemented using the LWP library, it will
only support the protocols that LWP supports.

=head1 SEE ALSO

L<mirror>, L<LWP>

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut

use LWP;
use LWP::Date qw(str2time time2str);
use URI::URL;
use Getopt::Std;

#use LWP::Debug;
#LWP::Debug::level('+trace');

$0 =~ s,.*/,,;  # use basename only

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

# "N" = Allowed without content in request
# "C" = Allowed with content in request
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

unless (getopts("hveEdb:t:i:c:m:")) {
    usage();
}

if ($opt_v) {
    die <<"EOT";
This is $0 version $VERSION (using LWP version $LWP::VERSION)

Copyright (C) 1995 Gisle Aas. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
EOT
}

usage() if $opt_h || !@ARGV;

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
    $ua->timeout($timeout);
}

if (defined $opt_i) {
    if (-e $opt_i) {
	$time = (stat _)[9];
    } else {
	$time = str2time($opt_i);
	die "$0: Illegal time syntax for -i option\n"
	    unless defined $time;
    }
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
    $request = new LWP::Request($method, $url);

    $request->header('If-Modified-Since', $opt_i) if defined $opt_i;
    $request->header('User-Agent', "LWP $0/$VERSION");
    $request->header('Accept', '*/*');
    if ($opt_c) { # will always be set for request that wants content
	$request->header('Content-Type', $opt_c);
	$request->header('Content-Length', length $content);
	$request->content($content);
    }

    if ($opt_E) {
	print STDERR $request->headers->as_string;
	print STDERR "----\n";  # 
    }

    $response = $ua->request($request);

    if ($opt_E || $opt_e) {
	# Display headers
	print STDERR $response->headers->as_string;
	print STDERR "\n";  # separate headers and content
    }

    if ($response->isSuccess) {
	print $response->content unless $opt_d;
    } else {
	print STDERR $response->errorAsHTML;
	$errors++;
    }
}

exit $errors;



sub usage
{
    die <<"EOT";
Usage: $0 [-options] <url>...
    -e            Display response headers
    -E            Display all headers (both request and response)
    -d            Don't display content
    -b <base>     Use the specified URL as base
    -t <timeout>  Set timeout value
    -i <time>     Set the If-Modified-Since header on the request
    -c <conttype> use this content-type for POST, PUT, CHECKIN
    -m <method>   use method for the request
    -v            Show program version
    -h            Print this message
EOT
}
