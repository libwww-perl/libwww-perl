#
# $Id: UserAgent.pm,v 1.8 1995/07/15 08:01:17 aas Exp $

package LWP::UserAgent;


=head1 NAME

LWP::UserAgent - A WWW UserAgent class

=head1 SYNOPSIS

 use LWP::UserAgent;
 $ua = new LWP::UserAgent;

 $request = new LWP::Request('file://localhost/etc/motd');

 $response = $ua->request($request); # or
 $response = $ua->request($request, '/tmp/sss'); # or
 $response = $ua->request($request, \&callback, 4096);

 sub callback { my($dataref, $response, $protocol) = @_; .... }

=head1 DESCRIPTION

C<LWP::UserAgent> is a class implementing a simple World-Wide Web user
agent in Perl. It brings together the Request/Response classes and the
Protocol classes that form the rest of the LWP library. For simple
uses this class can be used directly to dispatch WWW requests,
alternatively it can be subclassed for application-specific behaviour.

In normal usage the application creates a UserAgent object, and
configures it with values for timeouts proxies, name, etc. The next
step is to create an instance of C<LWP::Request> for the request that
needs to be performed. This request is then passed to the UserAgent 
C<request()> method, which dispatches it using the relevant protocol,
and returns a C<LWP::Reponse> object.

The C<request> method can process the content of the response in one
of three ways: into a scalar, into a file, or into repeated calls of a
subroutine. The scalar variant simply returns the content in a scalar
in the response object, and is suitable for small HTML replies that
might need further parsing.  The filename variant requires a scalar
containing a filename, and is suitable for large WWW objects which
need to be written directly to disc, without requiring large amounts
of memory. In this case the response object contains the name of the
file, but not the content. The subroutine variant requires a callback
routine and optional chuck size, and can be used to construct
"pipe-lined" processing, where processing of received chuncks can
begin before the complete data has arrived.  The callback is called with
3 arguments:  a reference to the data, a reference to the response
object and a reference to the protocol object.

Two advanced facilities allow the user of this module to finetune
timeouts and error handling:

By default the library uses alarm() to implement timeouts, dying if
the timeout occurs. If this is not required or interferes with other
parts of the application one can disable the use alarms. When alarms
are disabled timeouts can still occur for example when reading data,
but other cases like name lookups etc will not be timed out by the
library itself.

The library catches catches errors (such as internal errors and
timeouts) and present them as HTTP error responses. Alternatively
one can switch off this behaviour, and let the application handle
dies.

=head1 SEE ALSO

See L<LWP> for a complete overview of libwww-perl5.  See L<get> and
L<mirror> for examples of usage.

=head1 METHODS

=cut


#####################################################################


require LWP::MemberMixin;
@ISA = qw(LWP::MemberMixin);

require URI::URL;

require LWP::Request;
require LWP::Response;
require LWP::Protocol;
require LWP::Debug;
require LWP::Date;

use LWP::Base64 qw(Base64encode);

use Carp;

#####################################################################
#
# P U B L I C  M E T H O D S  S E C T I O N
#
#####################################################################

=head2 new()

Constructor for the UserAgent.

 $ua = new LWP::UserAgent;
 $ub = new LWP::UserAgent($ua);

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
                'maxRedirect' => 5,
        }, $class;
    }
}


sub clone
{
    my $self = shift;

    # this works because no values of %$self are references.
    bless { %$self }, ref $self;
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
        croak "ref is not an URI::URL object"
            unless ref($scheme) =~ "^URI::URL";
        $scheme = $scheme->abs->scheme;
    } else {
        croak "Illeal scheme '$scheme' passed to isProtocolSupported"
            if $scheme =~ /\W/;
        $scheme = lc $scheme;
    }
    return LWP::Protocol::implementor($scheme);
}


=head2 simpleRequest($request, $arg [, $size])

This method dispatches WWW requests on behalf of a user, and returns
the response received. See the description above for the use of the
method arguments.

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
            $response = $protocol->request($request, $proturl, 
                                           $arg, $size, $timeout);
        };
    } else {
        # user has to handle any dies, usually timeouts
        $response = $protocol->request($request, $proturl,
                                       $arg, $size, $timeout);
    }
    alarm(0) if ($self->useAlarm); # no more timeout
    
    if ($@) {
        if ($@ =~ /timeout/i) {
            $response = new LWP::Response(
                                 &LWP::StatusCode::RC_REQUEST_TIMEOUT,
                                 'User-agent timeout while ' .
                                          $LWP::Debug::timeoutMessage);
        }
        else {
            # Died on coding error
            $response = new LWP::Response(
                        &LWP::StatusCode::RC_INTERNAL_SERVER_ERROR, $@);
        }
    }

    return $response;
}


=head2 request($request, $arg [, $size])

Process a request, including redirects and security.
This method may actually send several different 
simple reqeusts.

This sub is getting a bit large...

=cut

sub request
{
    my($self, $request, $arg, $size, $depth, $seenref) = @_;

    LWP::Debug::trace('()');

    if (defined $depth) {
        die "Maximum number of redirects exceeded" if
            $depth > $self->{'maxRedirect'};
    } else {
        $depth = 0;
    }

    my $response = $self->simpleRequest($request, $arg, $size);
    
    my $code = $response->code;

    LWP::Debug::debug('Simple result: ' . LWP::StatusCode::message($code));

    if ($code == &LWP::StatusCode::RC_MOVED_PERMANENTLY or
        $code == &LWP::StatusCode::RC_MOVED_TEMPORARILY) {

        my $referral_uri = '';
        $referral_uri = $response->header('URI');
        $referral_uri = $response->header('Location') unless
            $referral_uri;
        $referral_uri = new URI::URL($referral_uri);

        my $referral = $request->clone;
        $referral->url($referral_uri);

        # XXX It'd be nice to add complete loop detection
        # so we could bail our before maxRedirect. In practice
        # I'd be surprised to see loops often, so we'll leave
        # it for now in the interest of simplicity

        return $self->request($referral, $arg, $size, $depth+1);

    } elsif ($code == &LWP::StatusCode::RC_UNAUTHORIZED) {

        my $challenge = $response->header('WWW-Authenticate');
        die "RC_UNAUTHORIZED without WWW-Authenticate\n" unless
            defined $challenge;

        if (($challenge =~ /^(Basic|\S+)\s+Realm="(.*?)"/i) or
            ($challenge =~ /^(Basic|\S+)\s+Realm=<([^<>]*)>/i)) {

            my($scheme, $realm) = ($1, $2);
            if ($scheme =~ /^Basic$/i) {

                my($uid, $pwd) = $self->getBasicCredentials($realm);

                if (defined $uid and defined $pwd) {
                    my $uidpwd = "$uid:$pwd";
                    my $header = $scheme . ' ' . &Base64encode($uidpwd);

                    # Need to check this isn't a repeated fail!
                    if (defined $seenref) {
                        if (exists $seenref->{"$realm $header"}) {
                            # here we know this failed before
                            $response->message('Invalid Credentials');
                            return $response;
                        }
                    } else {
                        $seenref = \%;
                    }
                    $seenref->{"$realm $header"} = 1;

                    my $referral = $request->clone;
                    $referral->header('Authorization', $header);

                    return $self->request($referral, $arg, $size, 
                                          $depth+1, $seenref);
                } else {
                    return $response; # no password found
                }
            } else {
                die "Authentication scheme '$scheme' not supported\n";
            }
        } else {
            die "Unknown challenge '$challenge'";
        }

    } elsif ($code == &LWP::StatusCode::RC_PAYMENT_REQUIRED or
             $code == &LWP::StatusCode::RC_PROXY_AUTHENTICATION_REQUIRED) {

        die 'Resolution of' . LWP::StatusCode::message($code) .
            'not yet implemented';
    }
    return $response;
}


sub credentials
{ 
    my($self, $realm, $uid, $pwd) = @_;
    @{ $self->{'basic_authentication'}{$realm} } = ($uid, $pwd);
}


=head2 getBasicCredentials($realm)

This is called by request() to retrieve credentials for a Realm
protected by Basic Authentication.

Should return username and password in a list.

This implementation simply checks a set of pre-stored member
variables. Subclasses can override this method to e.g. ask the user
for a username/password.

=cut

sub getBasicCredentials
{
    my($self, $realm) = @_;

    if (exists $self->{'basic_authentication'}{$realm}) {
        return @{ $self->{'basic_authentication'}{$realm} };
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
    my $request = new LWP::Request('GET', $url);

    if (-e $file) {
        my($mtime) = (stat($file))[9];
        if($mtime) {
            $request->header('If-Modified-Since',
                             LWP::Date::time2str($mtime));
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

    # Currently configured per scheme.
    # XXX Need to support exclusion domains for
    # first public release.
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
