#!/local/bin/perl -w

# $Id: lwp-mirror.PL,v 1.2 1995/07/13 14:08:42 aas Exp $
#
# Simple mirror utility using LWP

=head1 NAME

mirror - Simple mirror utility for WWW

=head1 SYNOPSIS

 mirror [-v] [-b <base URL>] [-t timeout] <url> <local file>

=head1 DESCRIPTION

This program can be used to mirror a document from a WWW server.  The
document is only transfered if the remote copy is newer than the local
copy.  If the local copy is newer nothing happens.

Use the C<-v> option to print the version number of this program.

The timeout value specified with the C<-t> option time that the program
will wait for response from the remote server before it fails.  The
default unit for the timeout value is seconds.  You might append "m"
to the timeout value to make it minutes.

Because this program is implemented using the LWP library, it only
supports the protocols that LWP supports.

=head1 SEE ALSO

L<get>, L<LWP>

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut


use LWP;
use URI::URL;
use Getopt::Std;

#use LWP::Debug;
#LWP::Debug::level('+trace');

$0 =~ s,.*/,,;  # use basename only

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

$ua = new LWP::UserAgent;

$opt_h = undef;  # print usage
$opt_v = undef;  # print version
$opt_b = undef;  # base url
$opt_t = undef;  # timeout

unless (getopts("hvb:t:")) {
    usage();
}

if ($opt_v) {
    die <<"EOT";
This is LWP $0 version $VERSION (using LWP version $LWP::VERSION)

Copyright (C) 1995 Gisle Aas. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
EOT
}

$url  = shift or usage();
$file = shift or usage();
usage() if $opt_h or @ARGV;

if (defined $opt_t) {
    $opt_t =~ /^(\d+)([smh])?/;
    die "$0: Illegal timeout value!\n" unless defined $1;
    $timeout = $1;
    $timeout *= 60   if ($2 eq "m");
    $timeout *= 3600 if ($2 eq "h");
    $ua->timeout($timeout);
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
Usage: $0 [-options] <url> <file>
    -v           print version number of program
    -b <base>    Use the specified URL as base
    -t <timeout> Set timeout value
EOT
}
