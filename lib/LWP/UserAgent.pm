# $Id: UserAgent.pm,v 1.44 1997/08/05 13:59:21 aas Exp $

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

The C<LWP::UserAgent> is a class implementing a simple World-Wide Web
user agent in Perl. It brings together the HTTP::Request,
HTTP::Response and the LWP::Protocol classes that form the rest of the
core of libwww-perl library. For simple uses this class can be used
directly to dispatch WWW requests, alternatively it can be subclassed
for application-specific behaviour.

In normal usage the application creates a UserAgent object, and then
configures it with values for timeouts proxies, name, etc. The next
step is to create an instance of C<HTTP::Request> for the request that
needs to be performed. This request is then passed to the UserAgent
request() method, which dispatches it using the relevant protocol,
and returns a C<HTTP::Response> object.

The basic approach of the library is to use HTTP style communication
for all protocol schemes, i.e. you will receive an C<HTTP::Response>
object also for gopher or ftp requests.  In order to achieve even more
similarities with HTTP style communications, gopher menus and file
directories will be converted to HTML documents.

The request() method can process the content of the response in one of
three ways: in core, into a file, or into repeated calls of a
subroutine.  You choose which one by the kind of value passed as the
second argument to request().

The in core variant simply returns the content in a scalar attribute
called content() of the response object, and is suitable for small
HTML replies that might need further parsing.  This variant is used if
the second argument is missing (or is undef).

The filename variant requires a scalar containing a filename as the
second argument to request(), and is suitable for large WWW objects
which need to be written directly to the file, without requiring large
amounts of memory. In this case the response object returned from
request() will have empty content().  If the request fails, then the
content() might not be empty, and the file will be untouched.

The subroutine variant requires a reference to callback routine as the
second argument to request() and it can also take an optional chuck
size as third argument.  This variant can be used to construct
"pipe-lined" processing, where processing of received chuncks can
begin before the complete data has arrived.  The callback function is
called with 3 arguments: the data received this time, a reference to
the response object and a reference to the protocol object.  The
response object returned from request() will have empty content().  If
the request fails, then the the callback routine will not have been
called, and the response->content() might not be empty.

The request can be aborted by calling die() within the callback
routine.  The die message will be available as the "X-Died" special
response header field.

The library also accepts that you put a subroutine reference as
content in the request object.  This subroutine should return the
content (possibly in pieces) when called.  It should return an empty
string when there is no more content.

The user of this module can finetune timeouts and error handling by
calling the use_alarm() and use_eval() methods.

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



require LWP::MemberMixin;
@ISA = qw(LWP::MemberMixin);

require URI::URL;
require HTTP::Request;
require HTTP::Response;

use HTTP::Date ();

use LWP ();
use LWP::Debug ();
use LWP::Protocol ();

use MIME::Base64 qw(encode_base64);
use Carp ();
use Config ();

use AutoLoader ();
*AUTOLOAD = \&AutoLoader::AUTOLOAD;  # import the AUTOLOAD method


=head2 $ua = new LWP::UserAgent;

Constructor for the UserAgent.  Returns a reference to a
LWP::UserAgent object.

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
		'agent'       => "libwww-perl/$LWP::VERSION",
		'from'        => undef,
		'timeout'     => 3*60,
		'proxy'       => undef,
		'use_eval'    => 1,
		'use_alarm'   => ($Config::Config{d_alarm} ?
				  $Config::Config{d_alarm} eq 'define' :
				  0),
                'parse_head'  => 1,
                'max_size'    => undef,
		'no_proxy'    => [],
	}, $class;
    }
}


=head2 $ua->simple_request($request, [$arg [, $size]])

This method dispatches a single WWW request on behalf of a user, and
returns the response received.  The C<$request> should be a reference
to a C<HTTP::Request> object with values defined for at least the
method() and url() attributes.

If C<$arg> is a scalar it is taken as a filename where the content of
the response is stored.

If C<$arg> is a reference to a subroutine, then this routine is called
as chunks of the content is received.  An optional C<$size> argument
is taken as a hint for an appropriate chunk size.

If C<$arg> is omitted, then the content is stored in the response
object itself.

=cut

sub simple_request
{
    my($self, $request, $arg, $size) = @_;
    local($SIG{__DIE__});  # protect agains user defined die handlers

    my($method, $url) = ($request->method, $request->url);

    # Check that we have a METHOD and a URL first
    return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST, "Method missing")
	unless $method;
    return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST, "URL missing")
	unless $url;

    LWP::Debug::trace("$method $url");

    # Locate protocol to use
    my $scheme = '';
    my $proxy = $self->_need_proxy($url);
    if (defined $proxy) {
	$scheme = $proxy->scheme;
    } else {
	$scheme = $url->scheme;
    }
    my $protocol;
    eval {
	$protocol = LWP::Protocol::create($scheme);
    };
    if ($@) {
	$@ =~ s/\s+at\s+\S+\s+line\s+\d+//;  # remove file/line number
	return HTTP::Response->new(&HTTP::Status::RC_NOT_IMPLEMENTED, $@)
    }

    # Extract fields that will be used below
    my ($agent, $from, $timeout, $use_alarm, $use_eval, $parse_head, $max_size) =
      @{$self}{qw(agent from timeout use_alarm use_eval parse_head max_size)};

    # Set User-Agent and From headers if they are defined
    $request->header('User-Agent' => $agent) if $agent;
    $request->header('From' => $from) if $from;

    # Inform the protocol if we need to use alarm() and parse_head()
    $protocol->use_alarm($use_alarm);
    $protocol->parse_head($parse_head);
    $protocol->max_size($max_size);
    
    # If we use alarm() we need to register a signal handler
    # and start the timeout
    if ($use_alarm) {
	$SIG{'ALRM'} = sub {
	    LWP::Debug::trace('timeout');
	    die 'Timeout';
	};
	$protocol->timeout($timeout);
	alarm($timeout);
    }

    if ($use_eval) {
	# we eval, and turn dies into responses below
	eval {
	    $response = $protocol->request($request, $proxy,
					   $arg, $size, $timeout);
	};
	if ($@) {
	    if ($@ =~ /^timeout/i) {
		$response = HTTP::Response->new(&HTTP::Status::RC_REQUEST_TIMEOUT, 'User-agent timeout');
	    } else {
		$@ =~ s/\s+at\s+\S+\s+line\s+\d+\s*//;  # remove file/line number
		$response = HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR, $@);
	    }
	}
    } else {
	# user has to handle any dies, usually timeouts
	$response = $protocol->request($request, $proxy,
				       $arg, $size, $timeout);
	# XXX: Should we die unless $response->is_success ???
    }
    alarm(0) if ($use_alarm); # no more timeout

    $response->request($request);  # record request for reference
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    return $response;
}


=head2 $ua->request($request, $arg [, $size])

Process a request, including redirects and security.  This method may
actually send several different simple reqeusts.

The arguments are the same as for C<simple_request()>.

=cut

sub request
{
    my($self, $request, $arg, $size, $previous) = @_;

    LWP::Debug::trace('()');

    my $response = $self->simple_request($request, $arg, $size);

    my $code = $response->code;
    $response->previous($previous) if defined $previous;

    LWP::Debug::debug('Simple result: ' . HTTP::Status::status_message($code));

    if ($code == &HTTP::Status::RC_MOVED_PERMANENTLY or
	$code == &HTTP::Status::RC_MOVED_TEMPORARILY) {

	# Make a copy of the request and initialize it with the new URI
	my $referral = $request->clone;

	# And then we update the URL based on the Location:-header.
	# Some servers erroneously return a relative URL for redirects,
	# so make it absolute if it not already is.
	my $referral_uri = (URI::URL->new($response->header('Location'),
					  $response->base))->abs();

	$referral->url($referral_uri);

	return $response unless $self->redirect_ok($referral);

	# Check for loop in the redirects
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
	    ($challenge =~ /^(\S+)\s+Realm\s*=\s*<([^<>]*)>/i) or
	    ($challenge =~ /^(\S+)$/)
	    ) {

	    my($scheme, $realm) = ($1, $2);
	    if ($scheme =~ /^Basic$/i) {

		my($uid, $pwd) = $self->get_basic_credentials($realm,
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
		    $referral->header('Authorization' => $header);

		    return $self->request($referral, $arg, $size, $response);
		} else {
		    return $response; # no password found
		}
	    } elsif ($scheme =~ /^Digest$/i) {
		# http://hopf.math.nwu.edu/digestauth/draft.rfc
		require MD5;
		my $md5 = new MD5;
		my($uid, $pwd) = $self->get_basic_credentials($realm,
							      $request->url);
		my $string = $challenge;
		$string =~ s/^$scheme\s+//;
		$string =~ s/"//g;                       #" unconfuse emacs
		my %mda = map { split(/,?\s+|=/) } $string;

		my(@digest);
		$md5->add(join(":", $uid, $mda{realm}, $pwd));
		push(@digest, $md5->hexdigest);
		$md5->reset;

		push(@digest, $mda{nonce});

		$md5->add(join(":", $request->method, $request->url->path));
		push(@digest, $md5->hexdigest);
		$md5->reset;

		$md5->add(join(":", @digest));
		my($digest) = $md5->hexdigest;
		$md5->reset;

		my %resp = map { $_ => $mda{$_} } qw(realm nonce opaque);
		@resp{qw(username uri response)} =
		  ($uid, $request->url->path, $digest);

		if (defined $uid and defined $pwd) {
		    my(@order) = qw(username realm nonce uri response);
		    if($request->method =~ /^(?:POST|PUT)$/) {
			$md5->add($request->content);
			my($content) = $md5->hexdigest;
			$md5->reset;
			$md5->add(join(":", @digest[0..1], $content));
			$md5->reset;
			$resp{"message-digest"} = $md5->hexdigest;
			push(@order, "message-digest");
		    }
		    push(@order, "opaque");
		    my @pairs;
		    for (@order) {
			next unless defined $resp{$_};
			push(@pairs, "$_=" . qq("$resp{$_}"));
		    }
		    my $header = "$scheme " . join(", ", @pairs);

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
		    #$referral->header('Extension' => "Security/Digest");
		    $referral->header('Authorization' => $header);
		    return $self->request($referral, $arg, $size, $response);
		} else {
		    return $response; # no password found
		}
	    } else {
		my $class = "LWP::Authen::$scheme";
		eval "use $class ()";
		if($@) {
		    warn $@;
		    warn "Authentication scheme '$scheme' not supported\n";
		    return $response;
		}
		return $class->authenticate($self, $response, $request, $arg, $size, $scheme, $realm);
	    } 
	} else {
	    warn "Unknown challenge '$challenge'";
	    return $response;
	}

    } elsif ($code == &HTTP::Status::RC_PAYMENT_REQUIRED or
	     $code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED) {
	warn 'Resolution of' . HTTP::Status::status_message($code) .
	     'not yet implemented';
	return $response;
    }
    $response;
}


=head2 $ua->redirect_ok

This method is called by request() before it tries to do any
redirects.  It should return a true value if the redirect is allowed
to be performed. Subclasses might want to override this.

The default implementation will return FALSE for POST request and TRUE
for all others.

=cut

sub redirect_ok
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


=head2 $ua->credentials($netloc, $realm, $uname, $pass)

Set the user name and password to be used for a realm.  It is often more
useful to specialize the get_basic_credentials() method instead.

=cut

sub credentials
{
    my($self, $netloc, $realm, $uid, $pass) = @_;
    @{ $self->{'basic_authentication'}{$netloc}{$realm} } = ($uid, $pass);
}


=head2 $ua->get_basic_credentials($realm, $uri)

This is called by request() to retrieve credentials for a Realm
protected by Basic Authentication or Digest Authentication.

Should return username and password in a list.  Return undef to abort
the authentication resolution atempts.

This implementation simply checks a set of pre-stored member
variables. Subclasses can override this method to e.g. ask the user
for a username/password.  An example of this can be found in
C<lwp-request> program distributed with this library.

=cut

sub get_basic_credentials
{
    my($self, $realm, $uri) = @_;
    my $netloc = $uri->netloc;

    if (exists $self->{'basic_authentication'}{$netloc}{$realm}) {
	return @{ $self->{'basic_authentication'}{$netloc}{$realm} };
    }

    return (undef, undef);
}


=head2 $ua->agent([$product_id])

Get/set the product token that is used to identify the user agent on
the network.  The agent value is sent as the "User-Agent" header in
the requests. The default agent name is "libwww-perl/#.##", where
"#.##" is substitued with the version numer of this library.

The user agent string should be one or more simple product identifiers
with an optional version number separated by the "/" character.
Examples are:

  $ua->agent('Checkbot/0.4 ' . $ua->agent);
  $ua->agent('Mozilla/5.0');

=head2 $ua->from([$email_address])

Get/set the Internet e-mail address for the human user who controls
the requesting user agent.  The address should be machine-usable, as
defined in RFC 822.  The from value is send as the "From" header in
the requests.  There is no default.  Example:

  $ua->from('aas@sn.no');

=head2 $ua->timeout([$secs])

Get/set the timeout value in seconds. The default timeout() value is
180 seconds, i.e. 3 minutes.

=head2 $ua->use_alarm([$boolean])

Get/set a value indicating wether to use alarm() when implementing
timeouts.  The default is TRUE, if your system supports it.  You can
disable it if it interfers with other uses of alarm in your application.

=head2 $ua->use_eval([$boolean])

Get/set a value indicating wether to handle internal errors internally
by trapping with eval.  The default is TRUE, i.e. the $ua->request()
will never die.

=head2 $ua->parse_head([$boolean])

Get/set a value indicating wether we should initialize response
headers from the E<lt>head> section of HTML documents. The default is
TRUE.  Do not turn this off, unless you know what you are doing.

=head2 $ua->max_size([$bytes])

Get/set the size limit for response content.  The default is undef,
which means that there is not limit.  If the returned response content
is only partial, because the size limit was exceeded, then a
"X-Content-Range" header will be added to the response.

=cut

sub timeout    { shift->_elem('timeout',   @_); }
sub agent      { shift->_elem('agent',     @_); }
sub from       { shift->_elem('from',      @_); }
sub use_alarm  { shift->_elem('use_alarm', @_); }
sub use_eval   { shift->_elem('use_eval',  @_); }
sub parse_head { shift->_elem('parse_head',@_); }
sub max_size   { shift->_elem('max_size',  @_); }


# Declarations of AutoLoaded methods
sub clone;
sub is_protocol_supported;
sub mirror;
sub proxy;
sub env_proxy;
sub no_proxy;
sub _need_proxy;


1;
__END__


=head2 $ua->clone;

Returns a copy of the LWP::UserAgent object

=cut


sub clone
{
    my $self = shift;
    my $copy = bless { %$self }, ref $self;  # copy most fields

    # elements that are references must be handled in a special way
    $copy->{'no_proxy'} = [ @{$self->{'no_proxy'}} ];  # copy array

    $copy;
}


=head2 $ua->is_protocol_supported($scheme)

You can use this method to query if the library currently support the
specified C<scheme>.  The C<scheme> might be a string (like 'http' or
'ftp') or it might be an URI::URL object reference.

=cut

sub is_protocol_supported
{
    my($self, $scheme) = @_;
    if (ref $scheme) {
	# assume we got a reference to an URI::URL object
	$scheme = $scheme->abs->scheme;
    } else {
	Carp::croak("Illeal scheme '$scheme' passed to is_protocol_supported")
	    if $scheme =~ /\W/;
	$scheme = lc $scheme;
    }
    return LWP::Protocol::implementor($scheme);
}


=head2 $ua->mirror($url, $file)

Get and store a document identified by a URL, using If-Modified-Since,
and checking of the Content-Length.  Returns a reference to the
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
	    $request->header('If-Modified-Since' =>
			     HTTP::Date::time2str($mtime));
	}
    }
    my $tmpfile = "$file-$$";

    my $response = $self->request($request, $tmpfile);
    if ($response->is_success) {

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

=head2 $ua->proxy(...)

Set/retrieve proxy URL for a scheme:

 $ua->proxy(['http', 'ftp'], 'http://proxy.sn.no:8001/');
 $ua->proxy('gopher', 'http://proxy.sn.no:8001/');

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

=head2 $ua->env_proxy()

Load proxy settings from *_proxy environment variables.  You might
specify proxies like this (sh-syntax):

  gopher_proxy=http://proxy.my.place/
  wais_proxy=http://proxy.my.place/
  no_proxy="my.place"
  export gopher_proxy wais_proxy no_proxy

Csh or tcsh users should use the C<setenv> command to define these
envirionment variables.

=cut

sub env_proxy {
    my ($self) = @_;
    while(($k, $v) = each %ENV) {
	$k = lc($k);
	next unless $k =~ /^(.*)_proxy$/;
	$k = $1;
	if ($k eq 'no') {
	    $self->no_proxy(split(/\s*,\s*/, $v));
	}
	else {
	    $self->proxy($k, $v);
	}
    }
}

=head2 $ua->no_proxy($domain,...)

Do not proxy requests to the given domains.  Calling no_proxy without
any domains clears the list of domains. Eg:

 $ua->no_proxy('localhost', 'no', ...);

=cut

sub no_proxy {
    my($self, @no) = @_;
    if (@no) {
	push(@{ $self->{'no_proxy'} }, @no);
    }
    else {
	$self->{'no_proxy'} = [];
    }
}


# Private method which returns the URL of the Proxy configured for this
# URL, or undefined if none is configured.
sub _need_proxy
{
    my($self, $url) = @_;

    $url = new URI::URL($url) unless ref $url;

    LWP::Debug::trace("($url)");

    # check the list of noproxies

    if (@{ $self->{'no_proxy'} }) {
	my $host = $url->host;
	return undef unless defined $host;
	my $domain;
	for $domain (@{ $self->{'no_proxy'} }) {
	    if ($host =~ /$domain$/) {
		LWP::Debug::trace("no_proxy configured");
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
