#
# $Id: UserAgent.pm,v 1.22 1995/09/04 20:53:51 aas Exp $

package LWP::UserAgent;


=head1 NAME

LWP::UserAgent - A WWW UserAgent class

=head1 SYNOPSIS

 require LWP::UserAgent;
 $ua = new LWP::UserAgent;

 $request = new HTTP::Request('GET', 'file://localhost/etc/motd');

 $response = $ua->request($request); # or
 $response = $ua->request($request, '/tmp/sss'); # or
 $response = $ua->request($request, \&callback, 4096);

 sub callback { my($data, $response, $protocol) = @_; .... }

=head1 DESCRIPTION

C<LWP::UserAgent> is a class implementing a simple World-Wide Web user
agent in Perl. It brings together the HTTP::Request, HTTP::Response
and the LWP::Protocol classes that form the rest of the libwww-perl
library. For simple uses this class can be used directly to dispatch
WWW requests, alternatively it can be subclassed for
application-specific behaviour.

In normal usage the application creates a UserAgent object, and
configures it with values for timeouts proxies, name, etc. The next
step is to create an instance of C<HTTP::Request> for the request that
needs to be performed. This request is then passed to the UserAgent
C<request()> method, which dispatches it using the relevant protocol,
and returns a C<HTTP::Response> object.

The basic approach of the library is to use HTTP style communication
for all protocol schemes, i.e. you will receive an C<HTTP::Response>
object also for gopher or ftp requests.  In order to achieve even more
similarities with HTTP style communications, gopher menus and file
directories will be converted to HTML documents.

The C<request> method can process the content of the response in one
of three ways: in core, into a file, or into repeated calls of a
subroutine. The in core variant simply returns the content in a scalar
attribute called C<content()> of the response object, and is suitable
for small HTML replies that might need further parsing.  The filename
variant requires a scalar containing a filename, and is suitable for
large WWW objects which need to be written directly to disc, without
requiring large amounts of memory. In this case the response object
contains the name of the file, but not the content. The subroutine
variant requires a callback routine and optional chuck size, and can
be used to construct "pipe-lined" processing, where processing of
received chuncks can begin before the complete data has arrived.  The
callback is called with 3 arguments: a the data, a reference to the
response object and a reference to the protocol object.

The library also accepts that you put a subroutine as content in the
request object.  This subroutine should return the content (possibly
in pieces) when called.  It should return an empty string when there
is no more content.

Two advanced facilities allow the user of this module to finetune
timeouts and error handling:

By default the library uses alarm() to implement timeouts, dying if
the timeout occurs. If this is not the prefered behaviour or it
interferes with other parts of the application one can disable the use
alarms. When alarms are disabled timeouts can still occur for example
when reading data, but other cases like name lookups etc will not be
timed out by the library itself.

The library catches errors (such as internal errors and timeouts) and
present them as HTTP error responses. Alternatively one can switch off
this behaviour, and let the application handle dies.

=head1 SEE ALSO

See L<LWP> for a complete overview of libwww-perl5.  See L<request> and
L<mirror> for examples of usage.

=head1 METHODS

=cut


#####################################################################


require LWP::MemberMixin;
@ISA = qw(LWP::MemberMixin);

require URI::URL;

require HTTP::Date;
require HTTP::Request;
require HTTP::Response;

require LWP::Debug;
require LWP::Protocol;

use MIME::Base64 qw(encode_base64);
use Carp;

#####################################################################
#
# P U B L I C  M E T H O D S  S E C T I O N
#
#####################################################################

=head2 new()

Constructor for the UserAgent.

 $ua = new LWP::UserAgent;
 $ub = new LWP::UserAgent($ua);  # clone existing UserAgent

=cut

sub new
{
    
    my($class, $init) = @_;

    LWP::Debug::trace('()');

    my $self;
    if (ref $init) {
        $self = $init->clone;
    } else {
        $self = bless {
                'agent'       => undef,
                'timeout'     => 3*60,
                'proxy'       => undef,
                'useEval'     => 1,
                'useAlarm'    => 1,
                'noProxy'     => [],
        }, $class;
    }
}


sub clone
{
    my $self = shift;
    my $copy = bless { %$self }, ref $self;  # copy most fields

    # elements that are references must be handled in a special way
    $copy->{'noProxy'} = [ @{$self->{'noProxy'}} ];  # copy array

    $copy;
}


=head2 isProtocolSupported($scheme)

You can use this method to query if the library currently support the
specified C<scheme>.  The C<scheme> might be a string (like 'http' or
'ftp') or it might be an URI::URL object reference.

=cut

sub isProtocolSupported
{
    my($self, $scheme) = @_;
    if (ref $scheme) {
        # assume we got a reference to an URI::URL object
        $scheme = $scheme->abs->scheme;
    } else {
        croak "Illeal scheme '$scheme' passed to isProtocolSupported"
            if $scheme =~ /\W/;
        $scheme = lc $scheme;
    }
    return LWP::Protocol::implementor($scheme);
}


=head2 simpleRequest($request, [$arg [, $size]])

This method dispatches a single WWW request on behalf of a user, and
returns the response received.  The C<$request> should be a reference
to a C<HTTP::Request> object with values defined for at least the
C<method()> and C<url()> attributes.

If C<$arg> is a scalar it is taken as a filename where the content of
the response is stored.

If C<$arg> is a reference to a subroutine, then this routine is called
as chunks of the content is received.  An optional C<$size> argument
is taken as a hint for an appropriate chunk size.

If C<$arg> is omitted, then the content is stored in the response
object.

=cut

sub simpleRequest
{
    my($self, $request, $arg, $size) = @_;

    LWP::Debug::trace('()');

    # Locate protocol to use
    my $url = $request->url;
    my $scheme = '';
    my $proxy = $self->_needProxy($url);
    if (defined $proxy) {
        $scheme = $proxy->scheme;
    } else {
        $scheme = $url->scheme;
    }
    my $protocol = LWP::Protocol::create($scheme);

    # Set User-Agent header if there is one
    my $agent = $self->agent;
    $request->header('User-Agent', $agent)
        if defined $agent and $agent;

    # If a timeout value has been set we pass it on to the protocol
    my $timeout = $self->timeout;

    # Inform the protocol if we need to use alarm()
    $protocol->useAlarm($self->useAlarm);

    # If we use alarm() we need to register a signal handler
    # and start the timeout
    if ($self->useAlarm) {
        $SIG{'ALRM'} = sub {
            LWP::Debug::trace('timeout');
            my $msg = 'Timeout';
            if (defined $LWP::Debug::timeoutMessage) {
                $msg .= ': ' . $LWP::Debug::timeoutMessage;
            }
            die $msg;
        };
        alarm($timeout);
    }

    if ($self->useEval) {
        # we eval, and turn dies into responses below
        eval {
            $response = $protocol->request($request, $proxy, 
                                           $arg, $size, $timeout);
        };
    } else {
        # user has to handle any dies, usually timeouts
        $response = $protocol->request($request, $proxy,
                                       $arg, $size, $timeout);
    }
    alarm(0) if ($self->useAlarm); # no more timeout
    
    if ($@) {
        if ($@ =~ /^timeout/i) {
            $response = new HTTP::Response
                                 &HTTP::Status::RC_REQUEST_TIMEOUT,
                                 'User-agent timeout while ' .
                                          $LWP::Debug::timeoutMessage;
        }
        else {
	    $@ =~ s/\s+at\s+\S+\s+line\s+\d+//;  # remove file/line number
            $response = new HTTP::Response
                        &HTTP::Status::RC_INTERNAL_SERVER_ERROR, $@;
        }
    }
    $response->request($request);  # record request for reference
    return $response;
}


=head2 request($request, $arg [, $size])

Process a request, including redirects and security.  This method may
actually send several different simple reqeusts.

The arguments are the same as for C<simpleRequest()>.

=cut

sub request
{
    my($self, $request, $arg, $size, $previous) = @_;

    LWP::Debug::trace('()');

    my $response = $self->simpleRequest($request, $arg, $size);
    my $code = $response->code;
    $response->previous($previous) if defined $previous;

    LWP::Debug::debug('Simple result: ' . HTTP::Status::statusMessage($code));

    if ($code == &HTTP::Status::RC_MOVED_PERMANENTLY or
        $code == &HTTP::Status::RC_MOVED_TEMPORARILY) {

        my $referral_uri =
	  new URI::URL $response->header('URI') || 
                       $response->header('Location');

        my $referral = $request->clone;
        $referral->url($referral_uri);
	return $response unless $self->redirectOK($referral);

	# Check for loop in redirects
	my $r = $response;
	while ($r) {
	    if ($r->request->url->as_string eq $referral_uri->as_string) {
		# loop detected
		$response->message("Loop detected");
		return $response;
	    }
	    $r = $r->previous;
	}

        return $self->request($referral, $arg, $size, $response);

    } elsif ($code == &HTTP::Status::RC_UNAUTHORIZED) {

        my $challenge = $response->header('WWW-Authenticate');
	unless (defined $challenge) {
	    warn "RC_UNAUTHORIZED without WWW-Authenticate\n";
	    return $response;
	}
        if (($challenge =~ /^(\S+)\s+Realm\s*=\s*"(.*?)"/i) or
            ($challenge =~ /^(\S+)\s+Realm\s*=\s*<([^<>]*)>/i)) {

            my($scheme, $realm) = ($1, $2);
            if ($scheme =~ /^Basic$/i) {

                my($uid, $pwd) = $self->getBasicCredentials($realm,
							    $request->url);

                if (defined $uid and defined $pwd) {
                    my $uidpwd = "$uid:$pwd";
                    my $header = "$scheme " . encode_base64($uidpwd, '');

                    # Need to check this isn't a repeated fail!
		    my $r = $response;
		    while ($r) {
			my $auth = $r->request->header('Authorization');
			if ($auth && $auth eq $header) {
			    # here we know this failed before
			    $response->message('Invalid Credentials');
			    return $response;
			}
			$r = $r->previous;
		    }

                    my $referral = $request->clone;
                    $referral->header('Authorization', $header);

                    return $self->request($referral, $arg, $size, $response);
                } else {
                    return $response; # no password found
                }
            } else {
                warn "Authentication scheme '$scheme' not supported\n";
		return $response;
            }
        } else {
            warn "Unknown challenge '$challenge'";
	    return $response;
        }

    } elsif ($code == &HTTP::Status::RC_PAYMENT_REQUIRED or
             $code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED) {
        warn 'Resolution of' . HTTP::Status::statusMessage($code) .
             'not yet implemented';
	return $response;
    }
    $response;
}


=head2 redirectOK

This method is called by request() before it tries to do any
redirects.  It should return a true value if the redirect is allowed
to be performed. Subclasses might want to override this.

=cut

sub redirectOK
{
    # draft-ietf-http-v10-spec-02.ps from www.ics.uci.edu, specify:
    # 
    # If the 30[12] status code is received in response to a request using
    # the POST method, the user agent must not automatically redirect the
    # request unless it can be confirmed by the user, since this might change
    # the conditions under which the request was issued.

    my($self, $request) = @_;
    return 0 if $request->method eq "POST";
    1;
}


sub credentials
{ 
    my($self, $netloc, $realm, $uid, $pass) = @_;
    @{ $self->{'basic_authentication'}{$netloc}{$realm} } = ($uid, $pass);
}


=head2 getBasicCredentials($realm, $uri)

This is called by request() to retrieve credentials for a Realm
protected by Basic Authentication.

Should return username and password in a list.  Return undef to abort
the authentication resolution atempts.

This implementation simply checks a set of pre-stored member
variables. Subclasses can override this method to e.g. ask the user
for a username/password.  An example of this can be found in
C<request> program distributed with this library.

=cut

sub getBasicCredentials
{
    my($self, $realm, $uri) = @_;
    my $netloc = $uri->netloc;

    if (exists $self->{'basic_authentication'}{$netloc}{$realm}) {
        return @{ $self->{'basic_authentication'}{$netloc}{$realm} };
    }

    return (undef, undef);
}



#####################################################################
#
# U T I L I T Y  S E C T I O N
#
#####################################################################

=head2 mirror($url, $file)

Get and store a document identified by a URL, using If-Modified-Since,
and checking of the content-length.  Returns a reference to the
response object.

=cut

sub mirror
{
    my($self, $url, $file) = @_;

    LWP::Debug::trace('()');
    my $request = new HTTP::Request('GET', $url);

    if (-e $file) {
        my($mtime) = (stat($file))[9];
        if($mtime) {
            $request->header('If-Modified-Since',
                             HTTP::Date::time2str($mtime));
        }
    }
    my $tmpfile = "$file-$$";

    my $response = $self->request($request, $tmpfile);
    if ($response->isSuccess) {
        
        my $file_length = (stat($tmpfile))[7];
        my($content_length) = $response->header('Content-length');
    
        if (defined $content_length and $file_length < $content_length) {
            unlink($tmpfile);
            die "Transfer truncated: " .
                "only $file_length out of $content_length bytes received\n";
        } elsif (defined $content_length and $file_length > $content_length) {
            unlink($tmpfile);
            die "Content-length mismatch: " .
                "expected $content_length bytes, got $file_length\n";
        } else {
            # OK
            rename($tmpfile, $file) or
                die "Cannot rename '$tmpfile' to '$file': $!\n";
        }
    } else {
        unlink($tmpfile);
    }
    return $response;
}

#####################################################################
#
# P R O P E R T I E S  S E C T I O N
#
#####################################################################

=head2 timeout()

=head2 agent()

=head2 useAlarm()

=head2 useEval()

Get/set member variables, respectively the timeout value in seconds,
the name of the agent, wether to use C<alarm()> or not, and wether to
use handle internal errors internally by trapping with eval.

=cut

sub timeout   { shift->_elem('timeout',  @_); }
sub agent     { shift->_elem('agent',    @_); }
sub useAlarm  { shift->_elem('useAlarm', @_); }
sub useEval   { shift->_elem('useEval',  @_); }


=head2 proxy(...)

Set/retrieve proxy URL for a scheme:

 $ua->proxy(['http', 'ftp'], 'http://www.oslonett.no:8001/');
 $ua->proxy('gopher', 'http://web.oslonett.no:8001/');

The first form specifies that the URL is to be used for proxying of
access methods listed in the list in the first method argument,
i.e. 'http' and 'ftp'.

The second form shows a shorthand form for specifying
proxy URL for a single access scheme.

=cut

sub proxy
{
    my($self, $key, $proxy) = @_;

    LWP::Debug::trace("$key, $proxy");

    if (!ref($key)) {   # single scalar passed
        my $old = $self->{'proxy'}{$key};
        $self->{'proxy'}{$key} = $proxy;
        return $old;    
    } elsif (ref($key) eq 'ARRAY') {
        for(@$key) {    # array passed
            $self->{'proxy'}{$_} = $proxy;
        }
    }
    return undef;
}

=head2 envProxy()

 $ua->envProxy();

Load proxy settings from *_proxy environment variables.

=cut

sub envProxy {
    my ($self) = @_;
    while(($k, $v) = each %ENV) {
        $k = lc($k);
        next unless $k =~ /^(.*)_proxy$/;
        if ($1 eq 'no') {
            $self->noProxy(split(/\s*,\s*/, $v));
        }
        else {
            $self->proxy($1, $v);           
        }
    }
}

=head2 noProxy($domain)

 $ua->noProxy('localhost', 'no', ...);

Do not proxy requests to the given domains.
Calling noProxy without domains clears the
list of domains.

=cut

sub noProxy {
    my($self, @no) = @_;
    if (@no) {
        push(@{ $self->{'noProxy'} }, @no);
    }
    else {
        $self->{'noProxy'} = [];
    }
}

#####################################################################
#
# P R I V A T E  S E C T I O N
#
#####################################################################


# Private method which returns the URL of the Proxy configured for this
# URL, or undefined if none is configured.
sub _needProxy
{
    my($self, $url) = @_;

    $url = new URI::URL($url) unless ref $url;

    LWP::Debug::trace("($url)");

    # check the list of noproxies

    if (@{ $self->{'noProxy'} }) {
        my $host = $url->host;
        my $domain;
        for $domain (@{ $self->{'noProxy'} }) {
            if ($host =~ /$domain$/) {
                LWP::Debug::trace("noProxy configured");
                return undef;
            }
        }
    }

    # Currently configured per scheme.
    # Eventually want finer granularity
    
    my $scheme = $url->scheme;
    if (exists $self->{'proxy'}{$scheme}) {

        LWP::Debug::debug('Proxied');
        return new URI::URL($self->{'proxy'}{$scheme});
    }

    LWP::Debug::debug('Not proxied');
    undef;
}

1;
