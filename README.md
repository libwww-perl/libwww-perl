# NAME

LWP::UserAgent - Web user agent class

# SYNOPSIS

    use strict;
    use warnings;
    use LWP::UserAgent ();

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->get('http://search.cpan.org/');

    if ($response->is_success) {
        print $response->decoded_content;  # or whatever
    }
    else {
        die $response->status_line;
    }

# DESCRIPTION

The [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) is a class implementing a web user agent.
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) objects can be used to dispatch web requests.

In normal use the application creates an [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object, and
then configures it with values for timeouts, proxies, name, etc. It
then creates an instance of [HTTP::Request](https://metacpan.org/pod/HTTP::Request) for the request that
needs to be performed. This request is then passed to one of the
request method the UserAgent, which dispatches it using the relevant
protocol, and returns a [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.  There are
convenience methods for sending the most common request types:
["get" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#get), ["head" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#head), ["post" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#post),
["put" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#put) and ["delete" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#delete).  When using these
methods, the creation of the request object is hidden as shown in the
synopsis above.

The basic approach of the library is to use HTTP-style communication
for all protocol schemes.  This means that you will construct
[HTTP::Request](https://metacpan.org/pod/HTTP::Request) objects and receive [HTTP::Response](https://metacpan.org/pod/HTTP::Response) objects even
for non-HTTP resources like _gopher_ and _ftp_.  In order to achieve
even more similarity to HTTP-style communications, _gopher_ menus and
file directories are converted to HTML documents.

# CONSTRUCTOR METHODS

The following constructor methods are available:

## clone

    my $ua2 = $ua->clone;

Returns a copy of the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object.

**CAVEAT**: Please be aware that the clone method does not copy or clone your
`cookie_jar` attribute. Due to the limited restrictions on what can be used
for your cookie jar, there is no way to clone the attribute. The `cookie_jar`
attribute will be `undef` in the new object instance.

## new

    my $ua = LWP::UserAgent->new( %options )

This method constructs a new [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options correspond to attribute methods described below:

    KEY                     DEFAULT
    -----------             --------------------
    agent                   "libwww-perl/#.###"
    from                    undef
    conn_cache              undef
    cookie_jar              undef
    default_headers         HTTP::Headers->new
    local_address           undef
    ssl_opts                { verify_hostname => 1 }
    max_size                undef
    max_redirect            7
    parse_head              1
    protocols_allowed       undef
    protocols_forbidden     undef
    requests_redirectable   ['GET', 'HEAD']
    timeout                 180
    proxy                   undef
    no_proxy                []

The following additional options are also accepted: If the `env_proxy` option
is passed in with a true value, then proxy settings are read from environment
variables (see ["env\_proxy" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#env_proxy)). If `env_proxy` isn't provided, the
`PERL_LWP_ENV_PROXY` environment variable controls if
["env\_proxy" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#env_proxy) is called during initialization.  If the
`keep_alive` option is passed in, then a `LWP::ConnCache` is set up (see
["conn\_cache" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#conn_cache)).  The `keep_alive` value is passed on as the
`total_capacity` for the connection cache.

`proxy` must be set as an arrayref of key/value pairs. `no_proxy` takes an
arrayref of domains.

# ATTRIBUTES

The settings of the configuration attributes modify the behaviour of the
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) when it dispatches requests.  Most of these can also
be initialized by options passed to the constructor method.

The following attribute methods are provided.  The attribute value is
left unchanged if no argument is given.  The return value from each
method is the old attribute value.

## agent

    my $agent = $ua->agent;
    $ua->agent('Checkbot/0.4 ');    # append the defaul to the end
    $ua->agent('Mozilla/5.0');
    $ua->agent("");                 # don't identify

Get/set the product token that is used to identify the user agent on
the network. The agent value is sent as the `User-Agent` header in
the requests.

The default is a string of the form `libwww-perl/#.###`, where `#.###` is
substituted with the version number of this library.

If the provided string ends with space, the default `libwww-perl/#.###`
string is appended to it.

The user agent string should be one or more simple product identifiers
with an optional version number separated by the `/` character.

## conn\_cache

    my $cache_obj = $ua->conn_cache;
    $ua->conn_cache( $cache_obj );

Get/set the [LWP::ConnCache](https://metacpan.org/pod/LWP::ConnCache) object to use.  See [LWP::ConnCache](https://metacpan.org/pod/LWP::ConnCache)
for details.

## cookie\_jar

    my $jar = $ua->cookie_jar;
    $ua->cookie_jar( $cookie_jar_obj );

Get/set the cookie jar object to use.  The only requirement is that
the cookie jar object must implement the `extract_cookies($response)` and
`add_cookie_header($request)` methods.  These methods will then be
invoked by the user agent as requests are sent and responses are
received.  Normally this will be a [HTTP::Cookies](https://metacpan.org/pod/HTTP::Cookies) object or some
subclass.

The default is to have no cookie jar, i.e. never automatically add
`Cookie` headers to the requests.

Shortcut: If a reference to a plain hash is passed in, it is replaced with an
instance of [HTTP::Cookies](https://metacpan.org/pod/HTTP::Cookies) that is initialized based on the hash. This form
also automatically loads the [HTTP::Cookies](https://metacpan.org/pod/HTTP::Cookies) module.  It means that:

    $ua->cookie_jar({ file => "$ENV{HOME}/.cookies.txt" });

is really just a shortcut for:

    require HTTP::Cookies;
    $ua->cookie_jar(HTTP::Cookies->new(file => "$ENV{HOME}/.cookies.txt"));

## credentials

    my $creds = $ua->credentials();
    $ua->credentials( $netloc, $realm );
    $ua->credentials( $netloc, $realm, $uname, $pass );
    $ua->credentials("www.example.com:80", "Some Realm", "foo", "secret");

Get/set the user name and password to be used for a realm.

The `$netloc` is a string of the form `<host>:<port>`.  The username and
password will only be passed to this server.

## default\_header

    $ua->default_header( $field );
    $ua->default_header( $field => $value );
    $ua->default_header('Accept-Encoding' => scalar HTTP::Message::decodable());
    $ua->default_header('Accept-Language' => "no, en");

This is just a shortcut for
`$ua->default_headers->header( $field => $value )`.

## default\_headers

    my $headers = $ua->default_headers;
    $ua->default_headers( $headers_obj );

Get/set the headers object that will provide default header values for
any requests sent.  By default this will be an empty [HTTP::Headers](https://metacpan.org/pod/HTTP::Headers)
object.

## from

    my $from = $ua->from;
    $ua->from('foo@bar.com');

Get/set the email address for the human user who controls
the requesting user agent.  The address should be machine-usable, as
defined in [RFC2822](https://tools.ietf.org/html/rfc2822). The `from` value
is sent as the `From` header in the requests.

The default is to not send a `From` header.  See
["default\_headers" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#default_headers) for the more general interface that allow
any header to be defaulted.

## local\_address

    my $address = $ua->local_address;
    $ua->local_address( $address );

Get/set the local interface to bind to for network connections.  The interface
can be specified as a hostname or an IP address.  This value is passed as the
`LocalAddr` argument to [IO::Socket::INET](https://metacpan.org/pod/IO::Socket::INET).

## max\_redirect

    my $max = $ua->max_redirect;
    $ua->max_redirect( $n );

This reads or sets the object's limit of how many times it will obey
redirection responses in a given request cycle.

By default, the value is `7`. This means that if you call ["request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#request)
and the response is a redirect elsewhere which is in turn a
redirect, and so on seven times, then LWP gives up after that seventh
request.

## max\_size

    my $size = $ua->max_size;
    $ua->max_size( $bytes );

Get/set the size limit for response content.  The default is `undef`,
which means that there is no limit.  If the returned response content
is only partial, because the size limit was exceeded, then a
`Client-Aborted` header will be added to the response.  The content
might end up longer than `max_size` as we abort once appending a
chunk of data makes the length exceed the limit.  The `Content-Length`
header, if present, will indicate the length of the full content and
will normally not be the same as `length($res->content)`.

## parse\_head

    my $bool = $ua->parse_head;
    $ua->parse_head( $boolean );

Get/set a value indicating whether we should initialize response
headers from the &lt;head> section of HTML documents. The default is
true. _Do not turn this off_ unless you know what you are doing.

## protocols\_allowed

    my $aref = $ua->protocols_allowed;      # get allowed protocols
    $ua->protocols_allowed( \@protocols );  # allow ONLY these
    $ua->protocols_allowed(undef);          # delete the list
    $ua->protocols_allowed(['http',]);      # ONLY allow http

By default, an object has neither a `protocols_allowed` list, nor a
["protocols\_forbidden" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#protocols_forbidden) list.

This reads (or sets) this user agent's list of protocols that the
request methods will exclusively allow.  The protocol names are case
insensitive.

For example: `$ua->protocols_allowed( [ 'http', 'https'] );`
means that this user agent will _allow only_ those protocols,
and attempts to use this user agent to access URLs with any other
schemes (like `ftp://...`) will result in a 500 error.

Note that having a `protocols_allowed` list causes any
["protocols\_forbidden" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#protocols_forbidden) list to be ignored.

## protocols\_forbidden

    my $aref = $ua->protocols_forbidden;    # get the forbidden list
    $ua->protocols_forbidden(\@protocols);  # do not allow these
    $ua->protocols_forbidden(['http',]);    # All http reqs get a 500
    $ua->protocols_forbidden(undef);        # delete the list

This reads (or sets) this user agent's list of protocols that the
request method will _not_ allow. The protocol names are case
insensitive.

For example: `$ua->protocols_forbidden( [ 'file', 'mailto'] );`
means that this user agent will _not_ allow those protocols, and
attempts to use this user agent to access URLs with those schemes
will result in a 500 error.

## requests\_redirectable

    my $aref = $ua->requests_redirectable;
    $ua->requests_redirectable( \@requests );
    $ua->requests_redirectable(['GET', 'HEAD',]); # the default

This reads or sets the object's list of request names that
["redirect\_ok" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#redirect_ok) will allow redirection for. By default, this
is `['GET', 'HEAD']`, as per [RFC 2616](https://tools.ietf.org/html/rfc2616).
To change to include `POST`, consider:

    push @{ $ua->requests_redirectable }, 'POST';

## show\_progress

    my $bool = $ua->show_progress;
    $ua->show_progress( $boolean );

Get/set a value indicating whether a progress bar should be displayed
on the terminal as requests are processed. The default is false.

## ssl\_opts

    my @keys = $ua->ssl_opts;
    my $val = $ua->ssl_opts( $key );
    $ua->ssl_opts( $key => $value );

Get/set the options for SSL connections.  Without argument return the list
of options keys currently set.  With a single argument return the current
value for the given option.  With 2 arguments set the option value and return
the old.  Setting an option to the value `undef` removes this option.

The options that LWP relates to are:

- `verify_hostname` => $bool

    When TRUE LWP will for secure protocol schemes ensure it connects to servers
    that have a valid certificate matching the expected hostname.  If FALSE no
    checks are made and you can't be sure that you communicate with the expected peer.
    The no checks behaviour was the default for libwww-perl-5.837 and earlier releases.

    This option is initialized from the `PERL_LWP_SSL_VERIFY_HOSTNAME` environment
    variable.  If this environment variable isn't set; then `verify_hostname`
    defaults to 1.

- `SSL_ca_file` => $path

    The path to a file containing Certificate Authority certificates.
    A default setting for this option is provided by checking the environment
    variables `PERL_LWP_SSL_CA_FILE` and `HTTPS_CA_FILE` in order.

- `SSL_ca_path` => $path

    The path to a directory containing files containing Certificate Authority
    certificates.
    A default setting for this option is provided by checking the environment
    variables `PERL_LWP_SSL_CA_PATH` and `HTTPS_CA_DIR` in order.

Other options can be set and are processed directly by the SSL Socket implementation
in use.  See [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) or [Net::SSL](https://metacpan.org/pod/Net::SSL) for details.

The libwww-perl core no longer bundles protocol plugins for SSL.  You will need
to install [LWP::Protocol::https](https://metacpan.org/pod/LWP::Protocol::https) separately to enable support for processing
https-URLs.

## timeout

    my $secs = $ua->timeout;
    $ua->timeout( $secs );

Get/set the timeout value in seconds. The default value is
180 seconds, i.e. 3 minutes.

The requests is aborted if no activity on the connection to the server
is observed for `timeout` seconds.  This means that the time it takes
for the complete transaction and the ["request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#request) method to
actually return might be longer.

# PROXY ATTRIBUTES

The following methods set up when requests should be passed via a
proxy server.

## env\_proxy

    $ua->env_proxy;

Load proxy settings from `*_proxy` environment variables.  You might
specify proxies like this (sh-syntax):

    gopher_proxy=http://proxy.my.place/
    wais_proxy=http://proxy.my.place/
    no_proxy="localhost,example.com"
    export gopher_proxy wais_proxy no_proxy

csh or tcsh users should use the `setenv` command to define these
environment variables.

On systems with case insensitive environment variables there exists a
name clash between the CGI environment variables and the `HTTP_PROXY`
environment variable normally picked up by `env_proxy`.  Because of
this `HTTP_PROXY` is not honored for CGI scripts.  The
`CGI_HTTP_PROXY` environment variable can be used instead.

## no\_proxy

    $ua->no_proxy( @domains );
    $ua->no_proxy('localhost', 'example.com');
    $ua->no_proxy(); # clear the list

Do not proxy requests to the given domains.  Calling `no_proxy` without
any domains clears the list of domains.

## proxy

    $ua->proxy(\@schemes, $proxy_url)
    $ua->proxy(['http', 'ftp'], 'http://proxy.sn.no:8001/');

    # For a single scheme:
    $ua->proxy($scheme, $proxy_url)
    $ua->proxy('gopher', 'http://proxy.sn.no:8001/');

    # To set multiple proxies at once:
    $ua->proxy([
        ftp => 'http://ftp.example.com:8001/',
        [ 'http', 'https' ] => 'http://http.example.com:8001/',
    ]);

Set/retrieve proxy URL for a scheme.

The first form specifies that the URL is to be used as a proxy for
access methods listed in the list in the first method argument,
i.e. `http` and `ftp`.

The second form shows a shorthand form for specifying
proxy URL for a single access scheme.

The third form demonstrates setting multiple proxies at once. This is also
the only form accepted by the constructor.

# HANDLERS

Handlers are code that injected at various phases during the
processing of requests.  The following methods are provided to manage
the active handlers:

## add\_handler

    $ua->add_handler( $phase => \&cb, %matchspec )

Add handler to be invoked in the given processing phase.  For how to
specify `%matchspec` see ["Matching" in HTTP::Config](https://metacpan.org/pod/HTTP::Config#Matching).

The possible values `$phase` and the corresponding callback signatures are:

- response\_data => sub { my($response, $ua, $h, $data) = @\_; ... }

    This handler is called for each chunk of data received for the
    response.  The handler might croak to abort the request.

    This handler needs to return a TRUE value to be called again for
    subsequent chunks for the same request.

- response\_done => sub { my($response, $ua, $h) = @\_; ... }

    The handler is called after the response has been fully received, but
    before any redirect handling is attempted.  The handler can be used to
    extract information or modify the response.

- response\_header => sub { my($response, $ua, $h) = @\_; ... }

    This handler is called right after the response headers have been
    received, but before any content data.  The handler might set up
    handlers for data and might croak to abort the request.

    The handler might set the $response->{default\_add\_content} value to
    control if any received data should be added to the response object
    directly.  This will initially be false if the $ua->request() method
    was called with a $content\_file or $content\_cb argument; otherwise true.

- request\_prepare => sub { my($request, $ua, $h) = @\_; ... }

    The handler is called before the request is sent and can modify the
    request any way it see fit.  This can for instance be used to add
    certain headers to specific requests.

    The method can assign a new request object to $\_\[0\] to replace the
    request that is sent fully.

    The return value from the callback is ignored.  If an exception is
    raised it will abort the request and make the request method return a
    "400 Bad request" response.

- request\_preprepare => sub { my($request, $ua, $h) = @\_; ... }

    The handler is called before the `request_prepare` and other standard
    initialization of the request.  This can be used to set up headers
    and attributes that the `request_prepare` handler depends on.  Proxy
    initialization should take place here; but in general don't register
    handlers for this phase.

- request\_send => sub { my($request, $ua, $h) = @\_; ... }

    This handler gets a chance of handling requests before they're sent to the
    protocol handlers.  It should return an HTTP::Response object if it
    wishes to terminate the processing; otherwise it should return nothing.

    The `response_header` and `response_data` handlers will not be
    invoked for this response, but the `response_done` will be.

- response\_redirect => sub { my($response, $ua, $h) = @\_; ... }

    The handler is called in $ua->request after `response_done`.  If the
    handler returns an HTTP::Request object we'll start over with processing
    this request instead.

## get\_my\_handler

    $ua->get_my_handler( $phase, %matchspec );
    $ua->get_my_handler( $phase, %matchspec, $init );

Will retrieve the matching handler as hash ref.

If `$init` is passed as a true value, create and add the
handler if it's not found.  If `$init` is a subroutine reference, then
it's called with the created handler hash as argument.  This sub might
populate the hash with extra fields; especially the callback.  If
`$init` is a hash reference, merge the hashes.

## handlers

    $ua->handlers( $phase, $request )
    $ua->handlers( $phase, $response )

Returns the handlers that apply to the given request or response at
the given processing phase.

## remove\_handler

    $ua->remove_handler( undef, %matchspec );
    $ua->remove_handler( $phase, %matchspec );
    $ua->remove_handlers(); # REMOVE ALL HANDLERS IN ALL PHASES

Remove handlers that match the given `%matchspec`.  If `$phase` is not
provided, remove handlers from all phases.

Be careful as calling this function with `%matchspec` that is not
specific enough can remove handlers not owned by you.  It's probably
better to use the ["set\_my\_handler" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#set_my_handler) method instead.

The removed handlers are returned.

## set\_my\_handler

    $ua->set_my_handler( $phase, $cb, %matchspec );
    $ua->set_my_handler($phase, undef); # remove handler for phase

Set handlers private to the executing subroutine.  Works by defaulting
an `owner` field to the `%matchspec` that holds the name of the called
subroutine.  You might pass an explicit `owner` to override this.

If $cb is passed as `undef`, remove the handler.

# REQUEST METHODS

The methods described in this section are used to dispatch requests
via the user agent.  The following request methods are provided:

## delete

    my $res = $ua->delete( $url );
    my $res = $ua->delete( $url, $field_name => $value, ... );

This method will dispatch a `DELETE` request on the given URL.  Additional
headers and content options are the same as for the ["get" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#get)
method.

This method will use the DELETE() function from [HTTP::Request::Common](https://metacpan.org/pod/HTTP::Request::Common)
to build the request.  See [HTTP::Request::Common](https://metacpan.org/pod/HTTP::Request::Common) for a details on
how to pass form content and other advanced features.

## get

    my $res = $ua->get( $url );
    my $res = $ua->get( $url , $field_name => $value, ... );

This method will dispatch a `GET` request on the given URL.  Further
arguments can be given to initialize the headers of the request. These
are given as separate name/value pairs.  The return value is a
response object.  See [HTTP::Response](https://metacpan.org/pod/HTTP::Response) for a description of the
interface it provides.

There will still be a response object returned when LWP can't connect to the
server specified in the URL or when other failures in protocol handlers occur.
These internal responses use the standard HTTP status codes, so the responses
can't be differentiated by testing the response status code alone.  Error
responses that LWP generates internally will have the "Client-Warning" header
set to the value "Internal response".  If you need to differentiate these
internal responses from responses that a remote server actually generates, you
need to test this header value.

Fields names that start with ":" are special.  These will not
initialize headers of the request but will determine how the response
content is treated.  The following special field names are recognized:

    :content_file   => $filename
    :content_cb     => \&callback
    :read_size_hint => $bytes

If a $filename is provided with the `:content_file` option, then the
response content will be saved here instead of in the response
object.  If a callback is provided with the `:content_cb` option then
this function will be called for each chunk of the response content as
it is received from the server.  If neither of these options are
given, then the response content will accumulate in the response
object itself.  This might not be suitable for very large response
bodies.  Only one of `:content_file` or `:content_cb` can be
specified.  The content of unsuccessful responses will always
accumulate in the response object itself, regardless of the
`:content_file` or `:content_cb` options passed in.  Note that errors
writing to the content file (for example due to permission denied
or the filesystem being full) will be reported via the `Client-Aborted`
or `X-Died` response headers, and not the `is_success` method.

The `:read_size_hint` option is passed to the protocol module which
will try to read data from the server in chunks of this size.  A
smaller value for the `:read_size_hint` will result in a higher
number of callback invocations.

The callback function is called with 3 arguments: a chunk of data, a
reference to the response object, and a reference to the protocol
object.  The callback can abort the request by invoking die().  The
exception message will show up as the "X-Died" header field in the
response returned by the get() function.

## head

    my $res = $ua->head( $url );
    my $res = $ua->head( $url , $field_name => $value, ... );

This method will dispatch a `HEAD` request on the given URL.
Otherwise it works like the ["get" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#get) method described above.

## is\_protocol\_supported

    my $bool = $ua->is_protocol_supported( $scheme );

You can use this method to test whether this user agent object supports the
specified `scheme`.  (The `scheme` might be a string (like `http` or
`ftp`) or it might be an [URI](https://metacpan.org/pod/URI) object reference.)

Whether a scheme is supported is determined by the user agent's
`protocols_allowed` or `protocols_forbidden` lists (if any), and by
the capabilities of LWP.  I.e., this will return true only if LWP
supports this protocol _and_ it's permitted for this particular
object.

## is\_online

    my $bool = $ua->is_online;

Tries to determine if you have access to the Internet. Returns `1` (true)
if the built-in heuristics determine that the user agent is
able to access the Internet (over HTTP) or `0` (false).

See also [LWP::Online](https://metacpan.org/pod/LWP::Online).

## mirror

    my $res = $ua->mirror( $url, $filename );

This method will get the document identified by URL and store it in
file called `$filename`.  If the file already exists, then the request
will contain an `If-Modified-Since` header matching the modification
time of the file.  If the document on the server has not changed since
this time, then nothing happens.  If the document has been updated, it
will be downloaded again.  The modification time of the file will be
forced to match that of the server.

The return value is an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.

## post

    my $res = $ua->post( $url, \%form );
    my $res = $ua->post( $url, \@form );
    my $res = $ua->post( $url, \%form, $field_name => $value, ... );
    my $res = $ua->post( $url, $field_name => $value, Content => \%form );
    my $res = $ua->post( $url, $field_name => $value, Content => \@form );
    my $res = $ua->post( $url, $field_name => $value, Content => $content );

This method will dispatch a `POST` request on the given URL, with
`%form` or `@form` providing the key/value pairs for the fill-in form
content. Additional headers and content options are the same as for
the ["get" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#get) method.

This method will use the `POST` function from [HTTP::Request::Common](https://metacpan.org/pod/HTTP::Request::Common)
to build the request.  See [HTTP::Request::Common](https://metacpan.org/pod/HTTP::Request::Common) for a details on
how to pass form content and other advanced features.

## put

    # Any version of HTTP::Message works with this form:
    my $res = $ua->put( $url, $field_name => $value, Content => $content );

    # Using hash or array references requires HTTP::Message >= 6.07
    use HTTP::Request 6.07;
    my $res = $ua->put( $url, \%form );
    my $res = $ua->put( $url, \@form );
    my $res = $ua->put( $url, \%form, $field_name => $value, ... );
    my $res = $ua->put( $url, $field_name => $value, Content => \%form );
    my $res = $ua->put( $url, $field_name => $value, Content => \@form );

This method will dispatch a `PUT` request on the given URL, with
`%form` or `@form` providing the key/value pairs for the fill-in form
content. Additional headers and content options are the same as for
the ["get" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#get) method.

CAVEAT:

This method can only accept content that is in key-value pairs when using
[HTTP::Request::Common](https://metacpan.org/pod/HTTP::Request::Common) prior to version `6.07`. Any use of hash or array
references will result in an error prior to version `6.07`.

This method will use the `PUT` function from [HTTP::Request::Common](https://metacpan.org/pod/HTTP::Request::Common)
to build the request.  See [HTTP::Request::Common](https://metacpan.org/pod/HTTP::Request::Common) for a details on
how to pass form content and other advanced features.

## request

    my $res = $ua->request( $request );
    my $res = $ua->request( $request, $content_file );
    my $res = $ua->request( $request, $content_cb );
    my $res = $ua->request( $request, $content_cb, $read_size_hint );

This method will dispatch the given `$request` object. Normally this
will be an instance of the [HTTP::Request](https://metacpan.org/pod/HTTP::Request) class, but any object with
a similar interface will do. The return value is an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.

The `request` method will process redirects and authentication
responses transparently. This means that it may actually send several
simple requests via the ["simple\_request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#simple_request) method described below.

The request methods described above; ["get" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#get), ["head" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#head),
["post" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#post) and ["mirror" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#mirror) will all dispatch the request
they build via this method. They are convenience methods that simply hide the
creation of the request object for you.

The `$content_file`, `$content_cb` and `$read_size_hint` all correspond to
options described with the ["get" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#get) method above. Note that errors
writing to the content file (for example due to permission denied
or the filesystem being full) will be reported via the `Client-Aborted`
or `X-Died` response headers, and not the `is_success` method.

You are allowed to use a CODE reference as `content` in the request
object passed in.  The `content` function should return the content
when called.  The content can be returned in chunks.  The content
function will be invoked repeatedly until it return an empty string to
signal that there is no more content.

## simple\_request

    my $request = HTTP::Request->new( ... );
    my $res = $ua->simple_request( $request );
    my $res = $ua->simple_request( $request, $content_file );
    my $res = $ua->simple_request( $request, $content_cb );
    my $res = $ua->simple_request( $request, $content_cb, $read_size_hint );

This method dispatches a single request and returns the response
received.  Arguments are the same as for the ["request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#request) described above.

The difference from ["request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#request) is that `simple_request` will not try to
handle redirects or authentication responses.  The ["request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#request) method
will, in fact, invoke this method for each simple request it sends.

# CALLBACK METHODS

The following methods will be invoked as requests are processed. These
methods are documented here because subclasses of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
might want to override their behaviour.

## get\_basic\_credentials

    # This checks wantarray and can either return an array:
    my ($user, $pass) = $ua->get_basic_credentials( $realm, $uri, $isproxy );
    # or a string that looks like "user:pass"
    my $creds = $ua->get_basic_credentials($realm, $uri, $isproxy);

This is called by ["request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#request) to retrieve credentials for documents
protected by Basic or Digest Authentication.  The arguments passed in
is the `$realm` provided by the server, the `$uri` requested and a
`boolean flag` to indicate if this is authentication against a proxy server.

The method should return a username and password.  It should return an
empty list to abort the authentication resolution attempt.  Subclasses
can override this method to prompt the user for the information. An
example of this can be found in `lwp-request` program distributed
with this library.

The base implementation simply checks a set of pre-stored member
variables, set up with the ["credentials" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#credentials) method.

## prepare\_request

    $request = $ua->prepare_request( $request );

This method is invoked by ["simple\_request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#simple_request). Its task is
to modify the given `$request` object by setting up various headers based
on the attributes of the user agent. The return value should normally be the
`$request` object passed in.  If a different request object is returned
it will be the one actually processed.

The headers affected by the base implementation are; `User-Agent`,
`From`, `Range` and `Cookie`.

## progress

    my $prog = $ua->progress( $status, $request_or_response );

This is called frequently as the response is received regardless of
how the content is processed.  The method is called with `$status`
"begin" at the start of processing the request and with `$state` "end"
before the request method returns.  In between these `$status` will be
the fraction of the response currently received or the string "tick"
if the fraction can't be calculated.

When `$status` is "begin" the second argument is the [HTTP::Request](https://metacpan.org/pod/HTTP::Request) object,
otherwise it is the [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.

## redirect\_ok

    my $bool = $ua->redirect_ok( $prospective_request, $response );

This method is called by ["request" in LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent#request) before it tries to follow a
redirection to the request in `$response`.  This should return a true
value if this redirection is permissible.  The `$prospective_request`
will be the request to be sent if this method returns true.

The base implementation will return false unless the method
is in the object's `requests_redirectable` list,
false if the proposed redirection is to a `file://...`
URL, and true otherwise.

# SEE ALSO

See [LWP](https://metacpan.org/pod/LWP) for a complete overview of libwww-perl5.  See [lwpcook](https://metacpan.org/pod/lwpcook)
and the scripts `lwp-request` and `lwp-download` for examples of
usage.

See [HTTP::Request](https://metacpan.org/pod/HTTP::Request) and [HTTP::Response](https://metacpan.org/pod/HTTP::Response) for a description of the
message objects dispatched and received.  See [HTTP::Request::Common](https://metacpan.org/pod/HTTP::Request::Common)
and [HTML::Form](https://metacpan.org/pod/HTML::Form) for other ways to build request objects.

See [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) and [WWW::Search](https://metacpan.org/pod/WWW::Search) for examples of more
specialized user agents based on [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

# COPYRIGHT AND LICENSE

Copyright 1995-2009 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
