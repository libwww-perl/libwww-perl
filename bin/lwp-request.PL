use Config;
unlink("bin/request");
open REQ, ">bin/request" or die "open for writing bin/request: $!";
print REQ "#!$Config{'scriptdir'}/perl -w\n";
print REQ <<'END'; chmod(0555, "bin/request");

# $Id: lwp-request.PL,v 1.11 1995/07/24 12:29:36 aas Exp $
#
# Simple user agent using LWP library.  Its interface is based on the
# libwww-perl-0.40 'get'-program.

=head1 NAME

request - Simple WWW user agent

=head1 SYNOPSIS

 request [-eEdvhx] [-m method] [-b <base URL>] [-t <timeout>]
         [-i <if-modified-since>] [-c <content-type>] 
         [-p <proxy-url>] <url>...

=head1 DESCRIPTION

This program can be used to send requests to WWW servers. The content
for POST, PUT and CHECKIN methods is read from stdin.  The content of
the response is printed on stdout.  Error messages are printed on
stderr.  The program returns a status value indicating the number of
URLs that failed.

The options are:

=over 3

=item -m <method>

Set which method to use for the request.  If this option is not used,
then the method is derived from the name of the program.

=item -f

Force request through, even if the program believes that the method is
illegal.

=item -b <url>

This URL will be used as the base URL for the URLs that the method is
applied to.  The base URL only takes effect for relative URLs.

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
requests that take a content, i.e. POST, PUT and CHECKIN.  You can
force methods to take content by using the C<-f> option together with
C<-c>.  The default Content-Type for POST is
C<application/x-www-form-urlencoded>.  The default Content-type for
the others are C<text/plain>.

=item -p <proxy-url>

Set the proxy to be used for the request(s).  The program also loads
proxy settings from the environment.  You can disable this with the
C<-P> option.

=back

The following options controls what is displayed by the program:

=over 3

=item -u

Print request method and absolute URL as requests are made.

=item -U

Print requeset headers in addition to request method and absolute URL.

=item -s

Print response status code.

=item -e

Print response headers.  This option is always on for HEAD requests.

=item -d

Do B<not> print the content of the response.

=item -v

Print the version number of the program and quit.

=item -h

Print usage message and quit.

=item -x

Extra debugging output.

=back

Because this program is implemented using the LWP library, it will
only support the protocols that LWP supports.

=head1 SEE ALSO

L<mirror>, L<LWP>

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut


$0 =~ s,.*/,,;  # use basename only
$VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);


require LWP;
require LWP::Date;
require URI::URL;

require LWP::Debug;


# This table lists the methods that are allowed.  It should really be
# a superset for all methods supported for every scheme that may be
# supported by the library.  Currently it might be a bit too HTTP
# specific.  You might use the -f option to force a method through.
#
# "" = No content in request, "C" = Needs content in request
#
%allowed_methods = (
    GET        => "",   
    HEAD       => "",
    POST       => "C",   
    PUT        => "C",
    DELETE     => "",   
    LINK       => "",
    UNLINK     => "",
    CHECKIN    => "C",
    CHECKOUT   => "",
    SHOWMETHOD => "",
);


$method = uc($0 eq "request" ? "GET" : $0);

# Parse command line
use Getopt::Std;

$opt_m = undef;  # set method
$opt_f = undef;  # make request even if method is now in %allowed_methods
$opt_b = undef;  # base url
$opt_t = undef;  # timeout
$opt_i = undef;  # if-modified-since
$opt_c = undef;  # content type for POST

$opt_u = undef;  # display method, URL and headers of request
$opt_U = undef;  # display request headers also
$opt_s = undef;  # display status code
$opt_e = undef;  # display response headers (default for HEAD)
$opt_d = undef;  # don't display content

$opt_h = undef;  # print usage
$opt_v = undef;  # print version

$opt_x = undef;  # extra debugging info
$opt_p = undef;  # proxy URL
$opt_P = undef;  # don't load proxy setting from environment

unless (getopts("xhvuUsedPp:b:t:i:c:m:f")) {
    usage();
}

if ($opt_v) {
    $lwpVersion = &LWP::Version;
    die <<"EOT";
This is $0 version $VERSION (using LWP version $lwpVersion)

Copyright (C) 1995 Gisle Aas. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
EOT
}

usage() if $opt_h || !@ARGV;

LWP::Debug::level('+') if $opt_x;

# Create the user agent object
$ua = new LWP::UserAgent;

# Load proxy settings from *_proxy environment variables.
$ua->envProxy unless $opt_P;

$method = $opt_m if defined $opt_m;

if ($opt_f) {
    if ($opt_c) {
        $allowed_methods{$method} = "C";
    } else {
        $allowed_methods{$method} = "";
    }
} elsif (!defined $allowed_methods{$method}) {
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
        $time = LWP::Date::str2time($opt_i);
        die "$0: Illegal time syntax for -i option\n"
            unless defined $time;
    }
    $opt_i = LWP::Date::time2str($time);
}

if (defined $opt_b) {
    $opt_b = new URI::URL $opt_b;
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

# Set up a request.  We use the same request for all URLs.
$request = new LWP::Request $method;
$request->header('If-Modified-Since', $opt_i) if defined $opt_i;
$request->header('User-Agent', "LWP $0/$VERSION");
$request->header('Accept', '*/*');
if ($opt_c) { # will always be set for request that wants content
    $request->header('Content-Type', $opt_c);
    $request->header('Content-Length', length $content);
    $request->content($content);
}


$errors = 0;

# Ok, now we perform the requests, one URL at a time
while ($url = shift) {

    $url = new URI::URL $url;

    $ua->proxy($url->scheme, $opt_p) if $opt_p;

    $request->url($url, $opt_b);

    $response = $ua->request($request);

    if ($opt_u || $opt_U) {
        my $url = $url->as_string;
        print "$method $url\n";
        print $request->headerAsString, "\n" if $opt_U;
    }

    if ($opt_s) {
        # Display status code
        require LWP::StatusCode;
        my $code = $response->code;
        print $code, " ", LWP::StatusCode::message($code), "\n";
        
    }

    if ($opt_e) {
        # Display headers
        print $response->headerAsString;
        print "\n";  # separate headers and content
    }

    if ($response->isSuccess) {
        print $response->content unless $opt_d;
    } else {
        print STDERR $response->errorAsHTML unless $opt_d;
        $errors++;
    }
}

exit $errors;



sub usage
{
    die <<"EOT";
Usage: $0 [-options] <url>...
    -m <method>   use method for the request (default is '$method')
    -f            make request even if $0 believes method is illegal
    -b <base>     Use the specified URL as base
    -t <timeout>  Set timeout value
    -i <time>     Set the If-Modified-Since header on the request
    -c <conttype> use this content-type for POST, PUT, CHECKIN
    -p <proxyurl> use this as a proxy
    -P            don't load proxy settings from environment

    -u            Display method and URL before any response
    -U            Display request headers after method and URL
    -s            Display response status code
    -e            Display response headers
    -d            Do not display content

    -v            Show program version
    -h            Print this message

    -x            Extra debugging output
EOT
}
END
