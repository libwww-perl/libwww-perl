#
# $Id: ftp.pm,v 1.6 1995/09/06 16:22:30 aas Exp $

# Implementation of the ftp protocol (RFC 959).

package LWP::Protocol::ftp;

require LWP::Protocol;
require LWP::Socket;
require HTTP::Request;
require HTTP::Response;
require HTTP::Status;

require LWP::MediaTypes;

use Carp;

@ISA = qw(LWP::Protocol);


sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;

    LWP::Debug::trace('ftp-request(' . 
                      (defined $request ? $request : '<undef>') . ', ' .
                      (defined $arg ? $arg : '<undef>') . ', ' .
                      (defined $size ? $size : '<undef>') .')');

    $size = 4096 unless defined $size and $size > 0;

    # check proxy
    if (defined $proxy)
    {
        return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
                                  'You can not proxy through the ftp';
    }

    my $url = $request->url;
    if ($url->scheme ne 'ftp') {
        my $scheme = $url->scheme;
        return new HTTP::Response &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
                       "LWP::Protocol::ftp::request called for '$scheme'";
    }

    # check method
    $method = $request->method;

    unless ($method eq 'GET' || $method eq 'HEAD' || $method eq 'PUT') {
        return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
                                  'Library does not allow method ' .
                                  "$method for 'ftp:' URLs";
    }

    my $host     = $url->host;
    my $port     = $url->port;
    my $user     = $url->user;
    my $password = $url->password;
    my $path     = $url->full_path;


# This is what RFC 1738 has to say about FTP access:
# --------------------------------------------------
# 
# 3.2. FTP
# 
#    The FTP URL scheme is used to designate files and directories on
#    Internet hosts accessible using the FTP protocol (RFC959).
# 
#    A FTP URL follow the syntax described in Section 3.1.  If :<port> is
#    omitted, the port defaults to 21.
# 
# 3.2.1. FTP Name and Password
# 
#    A user name and password may be supplied; they are used in the ftp
#    "USER" and "PASS" commands after first making the connection to the
#    FTP server.  If no user name or password is supplied and one is
#    requested by the FTP server, the conventions for "anonymous" FTP are
#    to be used, as follows:
# 
#         The user name "anonymous" is supplied.
# 
#         The password is supplied as the Internet e-mail address
#         of the end user accessing the resource.
# 
#    If the URL supplies a user name but no password, and the remote
#    server requests a password, the program interpreting the FTP URL
#    should request one from the user.
# 
# 3.2.2. FTP url-path
# 
#    The url-path of a FTP URL has the following syntax:
# 
#         <cwd1>/<cwd2>/.../<cwdN>/<name>;type=<typecode>
# 
#    Where <cwd1> through <cwdN> and <name> are (possibly encoded) strings
#    and <typecode> is one of the characters "a", "i", or "d".  The part
#    ";type=<typecode>" may be omitted. The <cwdx> and <name> parts may be
#    empty. The whole url-path may be omitted, including the "/"
#    delimiting it from the prefix containing user, password, host, and
#    port.
# 
#    The url-path is interpreted as a series of FTP commands as follows:
# 
#       Each of the <cwd> elements is to be supplied, sequentially, as the
#       argument to a CWD (change working directory) command.
# 
#       If the typecode is "d", perform a NLST (name list) command with
#       <name> as the argument, and interpret the results as a file
#       directory listing.
# 
#       Otherwise, perform a TYPE command with <typecode> as the argument,
#       and then access the file whose name is <name> (for example, using
#       the RETR command.)
# 
#    Within a name or CWD component, the characters "/" and ";" are
#    reserved and must be encoded. The components are decoded prior to
#    their use in the FTP protocol.  In particular, if the appropriate FTP
#    sequence to access a particular file requires supplying a string
#    containing a "/" as an argument to a CWD or RETR command, it is
#    necessary to encode each "/".
# 
#    For example, the URL <URL:ftp://myname@host.dom/%2Fetc/motd> is
#    interpreted by FTP-ing to "host.dom", logging in as "myname"
#    (prompting for a password if it is asked for), and then executing
#    "CWD /etc" and then "RETR motd". This has a different meaning from
#    <URL:ftp://myname@host.dom/etc/motd> which would "CWD etc" and then
#    "RETR motd"; the initial "CWD" might be executed relative to the
#    default directory for "myname". On the other hand,
#    <URL:ftp://myname@host.dom//etc/motd>, would "CWD " with a null
#    argument, then "CWD etc", and then "RETR motd".
# 
#    FTP URLs may also be used for other operations; for example, it is
#    possible to update a file on a remote file server, or infer
#    information about it from the directory listings. The mechanism for
#    doing so is not spelled out here.
# 
# 3.2.3. FTP Typecode is Optional
# 
#    The entire ;type=<typecode> part of a FTP URL is optional. If it is
#    omitted, the client program interpreting the URL must guess the
#    appropriate mode to use. In general, the data content type of a file
#    can only be guessed from the name, e.g., from the suffix of the name;
#    the appropriate type code to be used for transfer of the file can
#    then be deduced from the data content of the file.
# 
# 3.2.4 Hierarchy
# 
#    For some file systems, the "/" used to denote the hierarchical
#    structure of the URL corresponds to the delimiter used to construct a
#    file name hierarchy, and thus, the filename will look similar to the
#    URL path. This does NOT mean that the URL is a Unix filename.
# 
# 3.2.5. Optimization
# 
#    Clients accessing resources via FTP may employ additional heuristics
#    to optimize the interaction. For some FTP servers, for example, it
#    may be reasonable to keep the control connection open while accessing
#    multiple URLs from the same server. However, there is no common
#    hierarchical model to the FTP protocol, so if a directory change
#    command has been given, it is impossible in general to deduce what
#    sequence should be given to navigate to another directory for a
#    second retrieval, if the paths are different.  The only reliable
#    algorithm is to disconnect and reestablish the control connection.
# 

    my $response;

    my $cmd_sock = new LWP::Socket;
    alarm($timeout) if $self->useAlarm and defined $timeout;
    $cmd_sock->connect($host, $port);

    eval {
	expect($cmd_sock, '2');
	$cmd_sock->write("user $user\r\n");
	expect($cmd_sock, '3');
	$cmd_sock->write("pass $password\r\n");
	expect($cmd_sock, '2');
    };
    if ($@) {
	return new HTTP::Response &HTTP::Status::RC_UNAUTHORIZED, $@;
    }
    eval {
	$cmd_sock->write("type i\r\n");
	expect($cmd_sock, '2');

	# establish a data socket
	$listen = new LWP::Socket;
	$listen->listen(1);
	my $localhost = ($cmd_sock->getsockname)[0];
	$localhost =~ s/\./,/g;
	my $port = ($listen->getsockname)[1];
	$port = join(',', $port >> 8, $port & 0xFF);
	
	$cmd_sock->write("port $localhost,$port\r\n");
	$resp = expect($cmd_sock, '2');

	if ($method eq 'GET') {
	    $cmd_sock->write("retr $path\r\n");
	    $resp = expect($cmd_sock, '1', 1);
	    $response = new HTTP::Response &HTTP::Status::RC_OK,
	                                   'Document follows';
	    if ($resp =~ /\((\d+)\s+bytes\)/) {
		$response->header('Content-Length', $1);
	    }

	    my($type, @enc) = LWP::MediaTypes::guessMediaType($url);
	    $response->header('Content-Type',   $type) if $type;
	    for (@enc) {
		$response->pushHeader('Content-Encoding', $_);
	    }
	    
	    if ($resp =~ /^550/) {
		# 550 not a plain file, try to list instead
		$cmd_sock->write("list $path\r\n");
		expect($cmd_sock, '1');
		$response->header('Content-Type', # should be text/html
				  'text/x-dir-listing');
	    } elsif ($resp !~ /^1/) {
		die "$resp";
	    }
	    my $data = $listen->accept;
	    
	    $response = $self->collect($arg, $response, sub { 
		LWP::Debug::debug('collecting');
		my $content = '';
		my $result = $data->read(\$content, $size, $timeout);
		LWP::Debug::debug("collected: $content");
		return \$content;
	    } );

	} elsif ($method eq 'PUT') {
	    $cmd_sock->write("stor $path\r\n");
	    $resp = expect($cmd_sock, '1');
	    $response = new HTTP::Response &HTTP::Status::RC_CREATED,
	                                   'File updated';
	    my $data = $listen->accept;
	    my $content = $request->content;
	    my $bytes = 0;
	    if (defined $content) {
		if (ref($content) && ref($content) eq 'SCALAR') {
		    $bytes = $data->write($$content, $timeout);
		} else {
		    $bytes = $data->write($content, $timeout);
		}
	    }
	    $response->header('Content-Type', 'text/plain');
	    $response->content("$bytes stored as $path on $host\n")
	} else {
	    die "This should not happen\n";
	}

	$cmd_sock->write("quit\r\n");
	expect($cmd_sock, '2');
    };
    if ($@) {
	return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST, $@;
    }

    $response;
}

sub expect
{
    my($sock, $digit, $dont_die) = @_;
    my $response;
    $sock->readUntil("\r?\n", \$response, undef);
    my($code, $string) = $response =~ m/^(\d+)\s+(.*)/;
    die "$response\n" if substr($code,0,1) ne $digit && !$dont_die;
    LWP::Debug::debug($response);
    $response;
}

1;
