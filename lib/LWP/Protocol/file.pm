#
# $Id: file.pm,v 1.10 1995/09/15 17:05:35 aas Exp $

package LWP::Protocol::file;

require LWP::Protocol;
require LWP::MediaTypes;
require HTTP::Request;
require HTTP::Response;
require HTTP::Status;
require HTTP::Date;

use Carp;

@ISA = qw(LWP::Protocol);


sub request
{
    my($self, $request, $proxy, $arg, $size) = @_;

    LWP::Debug::trace('LWP::file::request(' . 
                      (defined $request ? $request : '<undef>') . ', ' .
                      (defined $arg ? $arg : '<undef>') . ', ' .
                      (defined $size ? $size : '<undef>') .')');

    $size = 4096 unless defined $size and $size > 0;

    # check proxy
    if (defined $proxy)
    {
        return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
                                  'You can not proxy through the filesystem';
    }

    # check method
    $method = $request->method;

    unless ($method eq 'GET' || $method eq 'HEAD') {
        return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
                                  'Library does not allow method ' .
                                  "$method for 'file:' URLs";
    }

    # check url
    my $url = $request->url;

    my $scheme = $url->scheme;
    if ($scheme ne 'file') {
        return new HTTP::Response &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
                                  "LWP::file::request called for '$scheme'";
    }

    my $host = $url->host;
    if ($host and $host !~ /^localhost$/i) {
        return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST_CLIENT,
                                  'Only file://localhost/ allowed';
    }

    # URL OK, look at file
    my $path = $url->full_path;

    # test file exists and is readable
    unless (-e $path) {
        return new HTTP::Response &HTTP::Status::RC_NOT_FOUND,
                                  "File `$path' does not exist";
    }
    unless (-r _) {
        return new HTTP::Response &HTTP::Status::RC_FORBIDDEN,
                                  'User does not have read permission';
    }

    # looks like file exists
    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
       $atime,$mtime,$ctime,$blksize,$blocks)
            = stat(_);

    # XXX should check Accept headers?

    # check if-modified-since
    my $ims = $request->header('If-Modified-Since');
    if (defined $ims) {
        my $time = HTTP::Date::str2time($ims);
        if (defined $time and $time >= $mtime) {
            return new HTTP::Response &HTTP::Status::RC_NOT_MODIFIED,
                                      "$method $path";
        }
    }

    # Ok, should be an OK response by now...
    $response = new HTTP::Response &HTTP::Status::RC_OK;
    
    # fill in response headers
    $response->header('Last-Modified', HTTP::Date::time2str($mtime));

    if (-d _) {         # If the path is a directory, process it
	unless ($path =~ m,/$,) {
	    # The path does not end with slash.  Return a redirect
	    # response to ensures that paths get correct.
	    my $resp = new HTTP::Response &HTTP::Status::RC_MOVED_PERMANENTLY,
	                                  "Missing slash in directory";
	    $resp->header('URI', "file:$path/");
	    return $resp;
	}
        # generate the HTML for directory
        opendir(D, $path) or
           return new HTTP::Response &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
                                     "Cannot read directory '$path': $!";
        my(@files) = sort readdir(D);
        closedir(D);
 
        # Make directory listing
        for (@files) {
            $_ .= "/" if -d "$path/$_";
            $_ = qq{<LI> <a href="$_">$_</a>};
        }
        my $html = join("\n",
                        "<HTML>\n<HEAD>",
                        "<TITLE>Directory $path</TITLE>",
                        "</HEAD>\n<BODY>",
                        "<UL>", @files, "</UL>",
                        "</BODY>\n</HTML>\n");

        $response->header('Content-Type',   'text/html');
        $response->header('Content-Length', length $html);

        # let's collect once
        my $first = 1;
        $response =  $self->collect($arg, $response, sub {
            if ($first) {
               $first = 0;
               return \$html;
            }
            return \ "";
        });
        
    } else {            # path is a regular file
        my($type, @enc) = LWP::MediaTypes::guessMediaType($path);
        $response->header('Content-Type',   $type) if $type;
        $response->header('Content-Length', $size);
	for (@enc) {
	    $response->pushHeader('Content-Encoding', $_);
	}

        # read the file
        open(F, $path) or return new 
           HTTP::Response(&HTTP::Status::RC_INTERNAL_SERVER_ERROR,
                          "Cannot read file '$path': $!");
        $response =  $self->collect($arg, $response, sub {
            my $content = "";
            my $bytes = sysread(F, $content, $size);
            return \$content if $bytes > 0;
            return \ "";
        });
        close(F);
    }

    $response;
}

1;
