#!/usr/local/bin/perl
#
# Test script for the libwww-perl5 test suite.
#
# $Id: lwp-test.pl,v 1.2 1995/07/16 07:06:20 aas Exp $

use CGI::Base qw(:DEFAULT :CGI);
use CGI::Request;

local $SIG{__WARN__} = sub {print @_, "<br>\n";};

&main;

sub main {
    my $req = new CGI::Request;

    my @path = ();
    if (defined $PATH_INFO and $PATH_INFO) {
        @path = split('/', $PATH_INFO);
        shift @path if ($path[0] eq ''); # loose empty component
    }
    else {
        &html('Missing PATH_INFO');
    }
    $test = shift(@path);

    if ($test eq 'simple-text') {
        &text("This is a simple text");
    }
    elsif ($test eq 'simple-html') {
        &html("This is a simple text");
    }
    elsif ($test eq 'timeout') {
        my $timeout = 5*60; # 5 minutes by default
        $timeout = $path[0] if defined $path[0] and $path[0] =~ /^\d+$/;
        sleep $timeout;
        &text("I slept $timeout seconds\n");
    }
    elsif ($test eq 'as_string') {
        print $req->as_string;
    }
    elsif ($test eq 'moved') {
        print "Location: file://localhost/etc/motd\n\n";
    }
    elsif ($test eq 'server-header') {
        print "Content-type: text/plain\r\n";
        print "Server-Header-Test: testing 1 2 3\r\n";
        print "\r\n";
        print "This response included a 'Server-Header-Test' field\n";
    }
    else {
        &html("Unknown test '$test'");
    }
}

sub text {
    my($msg) = @_;
    $msg = 'undef' unless defined $msg;
    my $title = 'LWP Test Suite';
    CGI::Base::SendHeaders("Content-type: text/plain\r\n");

    print $msg;
}

sub html {
    my($msg) = @_;
    $msg = 'undef' unless defined $msg;
    my $title = 'LWP Test Suite';
    CGI::Base::SendHeaders("Content-type: text/html\r\n");

    print <<EOM;
<HTML>
<HEAD>
<TITLE>
$title
</TITLE>
</HEAD>
<BODY>
<H1>$title</H1>
$msg
</BODY>
</HTML>
EOM
    exit;
}
