#!/usr/local/bin/perl
#
# $Id: file.pm,v 1.1 1995/06/11 23:29:43 aas Exp $

package LWP::Protocol::file;

require LWP::Protocol;
require LWP::Request;
require LWP::Response;
require LWP::MIMEtypes;
require LWP::StatusCode;
require LWP::Date;

use Carp;

@ISA = qw(LWP::Protocol);

# 0 = Not allowed (same as undefined / !exists)
# 1 = Allowed without content in request
# 2 = Allowed and with content in request
%AllowedMethods = (
    'GET'        => 1,
    'HEAD'       => 1,
);

# constructor inherited from LWP::Protocol

sub request {
    my($self, $request, $proxy, $arg, $size) = @_;

    $size = 4096 unless defined $size and $size > 0;

    # check proxy

    if (defined $proxy)
    {
        return new LWP::Response(&LWP::StatusCode::RC_BAD_REQUEST,
                                 q!You can't proxy through the filesystem!);
    }

    # check method

    $method = $request->method;

     unless (exists $AllowedMethods{$method} and
            defined $AllowedMethods{$method} and
            $AllowedMethods{$method} != 0 )
    {
        return new LWP::Response(&LWP::StatusCode::RC_BAD_REQUEST,
                                 'Library does not allow method ' .
                                 "$method for 'file:' URLs");
    }

    # check url

    my $url = $request->url;

    my $scheme = $url->scheme;
    if ($scheme ne 'file') {
        return new LWP::Response(&LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                                 "LWP::file::request called for '$scheme'");
    }

    my $host = $url->host();
    if ($host and $host !~ /^localhost$/i)
    {
        return new LWP::Response(&LWP::StatusCode::RC_BAD_REQUEST_CLIENT,
                                 'Only file://localhost/ allowed');
    }

    # URL OK, look at file

    my $path = $url->path();
    $path = "/" unless $path;

    # test file exists and is readable

    if (!(-e $path))
    {
        return new LWP::Response(&LWP::StatusCode::RC_NOT_FOUND,
                                 "File `$path' does not exist");
    }
    if (!(-r _))
    {
        return new LWP::Response(&LWP::StatusCode::RC_FORBIDDEN,
                                 'User does not have read permission');
    }

    # looks like file exists
    
    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
       $atime,$mtime,$ctime,$blksize,$blocks)
            = stat(_);

    # XXX should check Accept headers?

    # check if-modified-since

    my $ims = $request->header('If-modified-since');
    if (defined $ims) {
        my $time = &LWP::Date::str2time($ims);
        if (defined $time and $time >= $mtime) {
            $response = new LWP::file::Response(
                &LWP::StatusCode::RC_NOT_MODIFIED, $method, $path);         
        }
        else {
            $response = new LWP::Response(&LWP::StatusCode::RC_OK);
        }
    }
    else {
        $response = new LWP::Response(&LWP::StatusCode::RC_OK);
    }

    # fill in response headers

    $response->header('Last-Modified', $mtime);

    if (-d _)           # If the path is a directory, process it
    {
        $response->contentType('text/html');
        # won't know size until we generate the HTML
    }
    else {
        my($type) = &LWP::MIMEtypes::guessType($path);
        $response->header('Content-Type', $type) if ($type);
        $response->header('Content-Length', $size);
    }


    # on to the content

    # XXX this should use LWP::Protocol::collect()

    open(F, $path) or return new 
      LWP::Response(&LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                    "Cannot read file '$path': $!");

    if(!defined $arg) {
        # save into a scalar in the response
        undef($/);
        $response->content(<F>);
    }
    elsif (ref($arg)) {
        # pass to callback
        my $data = '';
        die "not yet";
        while($n = sysread(F, $data, $size)) {
            &$arg($response, $data);
        }
    }
    else {
        # save into file
        open(OUT, "> $arg") or return new
            LWP::Response(&LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                    "Cannot write to file '$arg': $!");
        my $data = 0;
        my $n = 0;
        while($n = sysread(F, $data, $size)) {
            print OUT $data;
        }
        close(OUT);
    }
    close(F);

    return $response;
}

1;
