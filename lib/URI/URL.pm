#!/usr/local/bin/perl -w
#
# $Id: URL.pm,v 2.9 1995/05/10 18:00:00 aas Exp $'
#
package URI::URL;
require 5.001;

#####################################################################

=head1 NAME

URI::URL - Uniform Resource Locators (absolute and relative)

=head1 SYNOPSIS

 use URI::URL;

 # Constructors
 $url1 = new URI::URL 'http://www.perl.com/%7Euser/gisle.gif';
 $url2 = new URI::URL 'gisle.gif', 'http://www.com/%7Euser';
 $url3 = $url2->abs; # get absolute url using base
 $url4 = $url2->abs('http:/other/path');

 $url5 = newlocal URI::URL;                # pwd
 $url6 = newlocal URI::URL '/tmp';         # dir
 $url7 = newlocal URI::URL '/etc/motd';    # file

 $url8 = $url1;            # copy references
 $url  = $url8->clone;     # copy objects

 # Stringify URL
 $str1 = $url->as_string;  # complete escaped URL string
 $str2 = $url->full_path;  # escaped path+query+params+frag
 $str3 = "$url";           # use operator overloading (experimental)

 # Retrieving Generic-RL components:
 $scheme   = $url->scheme;
 $netloc   = $url->netloc;  # see user,password,host,port below
 $path     = $url->path;
 $params   = $url->params;
 $query    = $url->query;
 $frag     = $url->frag;

 # Retrieving Network location (netloc) components:
 $user     = $url->user;
 $password = $url->password;
 $host     = $url->host;
 $port     = $url->port;     # returns default if not defined

 # Retrieving other attributes:
 $base     = $url->base;

 # Setting fields:
 # All methods above can set field values for example:
 $url->scheme('http');
 $url->host('www.w3.org');
 $url->port($url->default_port);
 $url->path('/welcome.html');
 $url->query('protocol info');
 $url->base($url5);  # use string or object

 # Specify unsafe characters to be escaped for this url
 $url->unsafe('\x00-\x20"\$#%;<>?\x7E-\xFF');

 # General method to get/set field values:
 $value  = $url->elem($name [, $new_value ]);

 # Port numbers
 $defport= $url->default_port;  # default port for scheme


 # Escaping functions (See 'HOW AND WHEN TO ESCAPE' below)
 $escaped   = uri_escape($component);
 $component = uri_unescape($escaped);

 # Other functions
 URI::URL::strict(0);                    # disable strict schemes
 URI::URL::implementor;                  # get generic implementor
 URI::URL::implementor($scheme);         # get scheme implementor
 URI::URL::implementor($scheme, $class); # set scheme implementor


=head1 DESCRIPTION

URL objects represent URLs (RFC 1738). Both absolute and relative
URL's are supported.

URL objects are created by C<new>, which takes a string
representation of a URL or an existing URL object reference to be
cloned. Specific individual elements can then be accessed via the
C<scheme>, C<user>, C<password>, C<host>, C<port>, C<path>, 
C<params>, C<query> and C<frag> methods. These methods can be 
called with a value to set the element to that value, and always 
return the old value. The C<elem> method provides a general
interface to access any element by name but it should be used with
caution: the effect of using incorrect spelling and case is
undefined.

The C<abs> function attempts to return a new absolute URL object
for a given URL.  In order to convert a relative URL into an absolute
one a I<base> URL is required. You can associate a default base with
a URL either by passing a C<base> to the C<new> method when a URL is
created or using the C<base> method on the object later.
Alternatively you can specify a one-off base as a parameter to the
C<abs> method.

The C<new> method must be able to determine the scheme for the URL.
If a scheme is not specified in the URL it will use the scheme
specified by the base URL. If no base URL scheme is defined then the
C<new> will croak unless URI::URL::strict(0) has been invoked, in
which case 'http' is silently assumed.

Once the scheme has been determined C<new> then uses the C<implementor>
function to determine which class implements that scheme.
If no implementor class is defined for the scheme then C<new> will
croak unless URI::URL::strict(0) has been invoked, in which case the
internal generic class is assumed.

Internally defined schemes are implemented by C<URI::URL::scheme_name>.
The URI::URL::implementor function can also be used to set the class
used to implement a scheme.


=head1 HOW AND WHEN TO ESCAPE

=over 3

=item An edited extract from a URI specification:

The printability requirement has been met by specifing a safe set of
characters, and a general escaping scheme for encoding "unsafe"
characters. This "safe" set is suitable, for example, for use in
electronic mail.  This is the canonical form of a URI.

There is a conflict between the need to be able to represent many
characters including spaces within a URI directly, and the need to be
able to use a URI in environments which have limited character sets
or in which certain characters are prone to corruption. This conflict
has been resolved by use of an hexadecimal escaping method which may
be applied to any characters forbidden in a given context. When URLs
are moved between contexts, the set of characters escaped may be
enlarged or reduced unambiguously.  The canonical form for URIs has
all white spaces encoded.


=item Notes:

A URL string I<must>, by definition, consist of escaped
components. Complete URL's are always escaped.

The components of a URL string must be I<individually> escaped.  Each
component of a URL may have a separate requirements regarding what
must be escaped, and those requirements are also dependent on the URL
scheme.

Never escape an already escaped component string.

=back

This implementation expects an escaped URL string to be passed to
C<new> and will return an escaped URL string from C<as_string>.

Internally the URL is stored in it's component parts.  Individual
components must be manipulated in unescaped form (this is most
natural anyway).

The escaping applied to a URL when it is constructed by C<as_string>
(or C<full_path>) can be controlled by using the C<unsafe> method to
specify which characters should be treated as unsafe.


=head1 ADDING NEW URL SCHEMES

New URL schemes or alternative implementations for existing schemes
can be added to your own code. To create a new scheme class use code
like:

   package MYURL::foo;              
   @ISA = (URI::URL::implementor);   # inherit from generic scheme

The 'URI::URL::implementor' function call with no parameters returns
the name of the class which implements the generic URL scheme
behaviour (typically C<URI::URL::_generic>). All schemes should be
derived from this class.

Your class can then define overriding methods (e.g., C<new()>,
C<_parse()> as required).

To register your new class as the implementor for a specific scheme
use code like:

   URI::URL::implementor('foo', 'MYURL::foo');

Any new URL created for scheme 'foo' will be implemented by your
C<MYURL::foo> class. Existing URLs will not be affected.


=head1 WHAT A URL IS NOT

URL objects do not, and should not, know how to 'get' or 'put' the
resources they specify locations for, anymore than a postal address
'knows' anything about the postal system. The actual access/transfer
should be achieved by some form of transport agent class. The agent
class can use the URL class, but should not be a subclass of it.


=head1 OUTSTANDING ISSUES

Need scheme-specific reserved characters, maybe even scheme/part
specific reserved chars...

The overloading interface is experimental. It is very useful
(especially for interpolating URL's into strings) but should not yet
be relied upon.


=head1 AUTHORS / ACKNOWLEDGMENTS

This module is (distantly) based on the C<wwwurl.pl> code in the
libwww-perl distribution developed by Roy Fielding
<fielding@ics.uci.edu>, as part of the Arcadia project at the
University of California, Irvine, with contributions from Brooks
Cutter.

Gisle Aas <aas@nr.no>, Tim Bunce <Tim.Bunce@ig.co.uk>, Roy Fielding
<fielding@ics.uci.edu> and Martijn Koster <m.koster@nexor.co.uk> (in
aplhabetical order) have collaborated on the complete rewrite for
Perl 5, with input from other people on the libwww-perl mailing list.

If you have any suggestions, bug reports, fixes, or enhancements,
send them to the libwww-perl mailing list at <libwww-perl@ics.uci.edu>.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

IN NO EVENT SHALL THE AUTHORS BE LIABLE TO ANY PARTY FOR DIRECT,
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT
LIMITED TO, LOST PROFITS) EVEN IF THE AUTHORS HAVE BEEN ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE. 

=head1 PREREQUISITES

You'll need Perl5.001 (including at least the four major patches) or
better.

=head1 AVAILABILITY

The latest version of this module is likely to be available from:

   http://www.ics.uci.edu/WebSoft/libwww-perl/contrib/
   http://web.nexor.co.uk/public/perl/perl.html

=head1 INSTALLING

Create a C<URI> subdirectory in your Perl 5 library directory
(often /usr/local/lib/perl5), and copy the C<URL.pm> file into it.

To execute the self-test move to the Perl 5 library directory and run
C<perl -w URI/URL.pm>

=head1 BUGS

Not all schemes are fully implemented. You'd want two-way functions
to get/set things like the News URL digits etc.

Non-http scheme specific escaping is not correct yet.

Note that running the module standalone will execute a substantial
self test.

=head1 METHODS AND FUNCTIONS

Below you'll find some descriptions of methods and functions.

=cut

#####################################################################
#
# Perl resumes here


use Carp;
require Cwd;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(uri_escape uri_unescape);

# Make the version number available
($Version) = '$Revision: 2.9 $' =~ /(\d+\.\d+)/;
$Version += 0;  # shut up -w

# Define default unsafe characters.
# Note that you cannot reliably change this at runtime
# because the substitutions which use it use the /o flag.
# XXX Should we include '~' or leave it to applications to
# add that if required?.
my $DefaultUnsafe = '\x00-\x20"#%;<>?\x7F-\xFF';

# Basic lexical elements, taken from RFC1738:
# (these are refered to by comments in the code)
# safe         = "$" | "-" | "_" | "." | "+"
# extra        = "!" | "*" | "'" | "(" | ")" | ","
# national     = "{" | "}" | "|" | "\" | "^" | "~" | "[" | "]" | "`"
# punctuation  = "<" | ">" | "#" | "%" | <">
# reserved     = ";" | "/" | "?" | ":" | "@" | "&" | "="
# escape       = "%" hex hex
# unreserved   = alpha | digit | safe | extra
# uchar        = unreserved | escape
# xchar        = unreserved | reserved | escape


$Debug = 0;             # set to 1 to print URL's on creation
my $UseCache = 1;       # see as_string method
my $StrictSchemes = 1;  # see new()

# schemes we have initialised:
my %ImplementedBy = ( '_generic' => 'URI::URL::_generic' );
# clases we have initialised:
my $Implementors  = ();

# Build a hex<->char map (HexHex->Char and Char->HexHex)
my %escapes;
map {
    my($hex, $chr) = (sprintf("%%%02X", $_), chr($_));
    $escapes{$chr}     = $hex;
} 0..255;

use strict qw(subs refs);


#####################################################################
#
# URL objects are iplemented as blessed hashes:
#
# Each of the URL components (scheme, user, password, host, port, 
# path, params, query, fragment) are stored under their name, in
# unquoted form.
# The '_str' key stores a cached stringified version of the URL
# (by definition in quoted form).
# The '_base' key stores the optional base of a relative URL.
# The '_unsafe' key stores the unsafe characters for this URL.
#
# Subclasses may add their own keys but must take great care to
# avoid names which might be used in later verions of this module.

# methods/functions

=head2 new

   $url = new URI::URL $escaped_string [, $optional_base_url]

This is the object constructor.  To trap bad or unknown URL schemes
use:

   $obj = eval { new URI::URL ... };

or set C<URI::URL::strict(0)> if you don't care about bad or unknown
schemes.

=cut

sub new
{
    my($class, $init, $base) = @_;

    my $self;
    if (ref $init) {
        $self = $init->clone;
        $self->base($base) if $base;
    } else {
        $init =~ s/^\s+//;  # remove leading space
        $init =~ s/\s.*//;  # remove anything after first word
        # We need a scheme to determine which class to use
        my($scheme) = $init =~ m/^([.+\-\w]+):/;
        if (!$scheme and $base){ # get scheme from base
            if (ref $base){ # may be object or just a string
                $scheme = $base->scheme;
            } else {
                $scheme = $1 if $base =~ m/^([.+\-\w]+):/;
            }
        }
        unless($scheme){
            croak "Unable to determine scheme for '$init'"
                if $StrictSchemes;
            $scheme = 'http';
        }
        my $impclass = URI::URL::implementor($scheme);
	unless ($impclass) {
	    croak "URI::URL scheme '$scheme' is not supported"
		if $StrictSchemes;
	    $impclass = URI::URL::implementor(); # use generic
	}

        # hand-off to scheme specific implementation sub-class
        $self = $impclass->new($init, $base);
    }
    return $self;
}


# Copy constructor

sub clone
{
    my $self = shift;
    bless { %$self }, ref $self;
}


=head2 newlocal

   $url = newlocal URI::URL $path;

Return a URL object that denotes a path on the local filesystem
(current directory by default).  Paths not starting with '/' are
taken relative to the current directory.

=cut

sub newlocal
{
    my($class, $path) = @_;
    my $url = new URI::URL "file://localhost/";
        
    unless (defined $path and $path =~ m:^/:) {
        my $cwd = Cwd::fastcwd();
        $cwd =~ s:/?$:/:; # force trailing slash on dir
        $path = (defined $path) ? $cwd . $path : $cwd;
    }
    $url->path($path);
    $url;
}


=head2 print_on

    $url->print_on(*FILEHANDLE);

Prints a verbose presentation of the contents of the URL object to
the specified file handle (default STDOUT).  Mainly useful for
debugging.

=cut

sub print_on
{
    no strict qw(refs);  # because we use strings as filehandles
    my $self = shift;
    my $fh = shift || 'STDOUT';
    my($k, $v);
    print $fh "Dump of URL $self...\n";
    foreach $k (sort keys %$self){
        $v = $self->{$k};
        $v = 'UNDEF' unless defined $v;
        print $fh "  $k\t'$v'\n";
    }
}

sub strict
{
    return $StrictSchemes unless @_;
    my $old = $StrictSchemes;
    $StrictSchemes = $_[0];
    $old;
}

=head2 URI::URL::implementor

   URI::URL::implementor;
   URI::URL::implementor($scheme);
   URI::URL::implementor($scheme, $class);

Get and/or set implementor class for a scheme.
Returns '' if specified scheme is not supported.
Returns generic URL class if no scheme specified.

=cut

sub implementor {
    my($scheme, $impclass) = @_;
    my $ic;
    $scheme = (defined $scheme) ? lc($scheme) : '_generic';

    if ($impclass) {
	$impclass->_init_implementor($scheme);
	$ImplementedBy{$scheme} = $impclass;
    }
    return $ic if $ic=$ImplementedBy{$scheme};

    # scheme not yet known, look for internal implementation
    $ic = "URI::URL::$scheme";	# default location
    no strict qw(refs);
    # check we actually have one for the scheme:
    $ic = '' unless defined @{"${ic}::ISA"};
    if ($ic) {
	$ic->_init_implementor;
	$ImplementedBy{$scheme} = $ic;
    }
    $ic;
}


sub _init_implementor			# private method
{
    my($class) = @_;
    # Remember that one implementor class may actually
    # serve to implement several URL schemes.

    # have we already initialised this class?
    return 1 if exists $Implementors{$class};

    no strict qw(refs);
    # Setup overloading - experimental
    %{"${class}::OVERLOAD"} = %URI::URL::_generic::OVERLOAD
	unless defined %{"${class}::OVERLOAD"};
    $Implementors{$class} = 1;
    1;	# success, one day we may also want to indicate failure
}


#####################################################################
#
# Methods to handle URL's elements

# These methods always return the current value,
# so you can use $url->scheme to read the current value.
# If a new value is passed, e.g. $url->scheme('http'),
# it also sets the new value, and returns the previous value.
# Use $url->scheme(undef) to set the value to undefined.

# Generic-RL components:
sub scheme   { shift->elem('scheme',  @_); }
sub netloc   { shift->elem('netloc',  @_); }
sub path     { shift->elem('path',    @_); }
sub params   { shift->elem('params',  @_); }
sub query    { shift->elem('query',   @_); }
sub frag     { shift->elem('frag',    @_); }

# Fields derived from generic netloc:
sub user     { shift->elem('user',    @_); }
sub password { shift->elem('password',@_); }
sub host     { shift->elem('host',    @_); }
sub port {
    my($self, $port) = @_;
    if (@_ > 1) {     # set
      # if port is default then unset it (simplifies comparisons)
      $port = undef if ($port and $port == $self->default_port);
      return $self->elem('port', $port);
    }
    # get, return default if unset
    $self->elem('port') || $self->default_port;
}


# optimisation to speed up elem() below:
my %netloc_fields = qw(user 1 password 1 host 1 port 1);

sub elem {
    my($self, $element, @val) = @_;
    my $old = $self->{$element};
    return $old unless @val;

    $self->{$element} = $val[0]; # general case
    $self->{'_str'} = '';        # void cached string
    
    # netloc includes user, password, host and port
    if ($element eq 'netloc') {
        $self->_read_netloc();  # update parts from whole
    }
    elsif (exists $netloc_fields{$element}) {
        $self->_write_netloc(); # update whole from parts
    }
    return $old;
}

# Other attributes of a URL object:
# (These may happen to use elem() but applications should not
# use elem() to access them).

sub base {
    my $self = shift;
    return $self->elem('_base', @_) if @_;      # set
    # The base attribute supports 'lazy' conversion from URL strings
    # to URL objects. Strings may be stored but when a string is
    # fetched it will automatically be converted to a URL object.
    # The main benefit is to make it much cheaper to say:
    #   new URI::URL $random_url_string 'http:'
    my $base = $self->elem('_base');            # get
    return undef unless defined $base;
    unless (ref $base){
        $base = new URI::URL $base;
        $self->elem('_base', $base); # set new object
    }
    $base;
}

sub unsafe {
    shift->elem('_unsafe', @_);
}


#####################################################################
#
# escape()
# unescape()
#
#  Generic escaping ('this has spaces' -> 'this%20has%20spaces')
#    and unescaping ('this%20has%20spaces' -> 'this has spaces')
#  Overridden by subclasses which need more control.
#  See notes on escaping at top of module.
#
sub escape
{
    my($self, $text, $patn) = @_;
    if ($patn){
        $text =~ s/([$patn])/$escapes{$1}/eg;
        return $text;
    }
    # let perl pre-compile this default for max speed
    $text =~ s/([$DefaultUnsafe])/$escapes{$1}/oeg;
    $text;
}

# Define method aliases so that subclasses can control escaping at
# a finer granularity. Doing it this way has practically zero cost.
# Only of significant value to classes which rely on the default
# full_path() and as_string() methods.
*_esc_netloc = \&escape;
*_esc_path   = \&escape;
*_esc_params = \&escape;
*_esc_frag   = \&escape;

sub _esc_query {
    my($self, $text, @unsafe) = @_;
    $text =~ s/ /+/g;	# RFC1630
    my $text = $self->escape($text, @unsafe);
}


sub unescape
{
    my($self, $text) = @_;
    return undef unless defined $text;
    # Note from RFC1630:  "Sequences which start with a percent sign
    # but are not followed by two hexadecimal characters are reserved
    # for future extension"
    $text =~ s/%([\dA-Fa-f][\dA-Fa-f])/chr(hex($1))/eg;
    $text;
}

# We don't bother defining method aliases for unescape because
# unescape does not need such fine control.


#####################################################################
#
# Miscellaneous functions (NON-METHODS)

# uri_escape()
#
# Apply URI character escaping rules to some text.
# Note that it is generally better to do something like this:
#       $url = new URI::URL 'http:';
#       $url->path($random_query);
# See the 'HOW AND WHEN TO ESCAPE' section in the pod text above.
#
sub uri_escape
{
    URI::URL->escape(@_);
}

# uri_unescape()
#
# Unescape some text destined to be a component of a URL.
# Note that it is generally better to do something like this:
#       $url->path(uri_unescape($pre_escaped_path));
# See the 'HOW AND WHEN TO ESCAPE' section in the pod text above.
#
sub uri_unescape
{
    URI::URL->unescape(@_);
}


#####################################################################
#
#       Internal pre-defined generic scheme support
#
# In this implementation all schemes are subclassed from
# URI::URL::_generic. This turns out to have reasonable mileage.
# See also draft-ietf-uri-relative-url-06.txt

package URI::URL::_generic;           # base support for generic-RL's

use Carp;
@ISA = qw(URI::URL);
%OVERLOAD = ( '""'=>'as_string', 'fallback'=>1 );	# EXPERIMENTAL

sub new {                               # inherited by subclasses
    my($class, $init, $base) = @_;
    my $url = bless {}, $class;         # create empty object
    $url->_parse($init);                # parse $init into components
    $url->base($base) if $base;
    $url->print_on('STDERR') if $URI::URL::Debug;
    $url;
}


# Generic-RL parser
# See draft-ietf-uri-relative-url-06.txt Section 2

sub _parse {
    my($self, $u) = @_;
    $self->{'_orig_url'} = $u if $URI::URL::Debug;      
    # draft-ietf-uri-relative-url-06.txt Section 2.4
    # 2.4.1
    $self->{frag}   = $self->unescape($1) if $u =~ s/#(.*)$//;
    # 2.4.2
    $self->{scheme} = lc($1)   if $u =~ s/^\s*([\w\+\.\-]+)://;
    # 2.4.3
    $self->{netloc} = $self->unescape($1) if $u =~ s!^//([^/]*)!!;
    # 2.4.4
    if ($u =~ s/\?(.*)//){	# '+' -> ' ' for queries (RFC1630)
	my $query = $1;
	$query =~ s/\+/ /g;
	$self->{query}  = $self->unescape($query)
    }
    # 2.4.5
    $self->{params} = $self->unescape($1) if $u =~ s/;(.*)//;
    # 2.4.6
    $self->{path}   = $self->unescape($u);
    # read netloc components: "<user>:<password>@<host>:<port>"
    $self->_read_netloc;
    1;
}

sub _read_netloc {      # netloc -> user, password, host, post
    my($self) = @_;
    my $nl = $self->{netloc} || ''; # already unescaped
    $self->{'_str'} = '';       # void cache
    if ($nl =~ s/^([^:@]*):?(.*?)@//){
        $self->{user}     = $1;
        $self->{password} = $2 if $2 ne '';
    }
    if ($nl =~ s/^([^:]*):?(\d*)//){
        $self->{host} = $1;
        $self->{port} = $2 if $2 ne '';
    }
}

sub _write_netloc {     # user, password, host, post -> netloc
    my($self) = @_;
    my $tmp;
    my $nl = $self->{user} || '';
    $nl .= ":$self->{password}" if $nl and $self->{password};
    $nl .= "\@" if $nl;
    $nl .= ($tmp = $self->{host});
    $nl .= ":$tmp" if ($tmp && ($tmp=$self->{port})
                            && $tmp != $self->default_port);
    $self->{netloc} = $nl;
}



# Generic-RL stringify
#
sub as_string
{
    my $self = shift;
    return $self->{'_str'} if $self->{'_str'} and 
        $UseCache;

    # use @ here to avoid undef warnings and allow $self->escape
    # to use optimised pattern if no override has been set.
    my @unsafe = shift || $self->unsafe || ();
    my($scheme, $netloc, $port) = @{$self}{qw(scheme netloc port)};

    # full_path() -> path+query+params+frag (escaped)
    my $path  = $self->full_path(@unsafe);

    if ($netloc){
        $path = "/$path" unless $path =~ m:^/:;
        $path = "//".$self->_esc_netloc($netloc, @unsafe).$path;
    }
    my $urlstr = ($scheme) ? "$scheme:$path" : $path;
    $self->{'_str'} = $urlstr;  # set cache
    return $urlstr;
}


# Generic-RL stringify full path (path+query+params+frag)
#
sub full_path
{
    my $self = shift;
    # use @ here to avoid undef warnings and allow $self->escape
    # to use optimised pattern if no override has been set.
    my @unsafe = shift || $self->unsafe || ();
    my($path, $params, $query, $frag)
        = @{$self}{qw(path params query frag) };
    my $u = '';
    $u .=     $self->_esc_path($path,    @unsafe) if $path;
    $u .= ";".$self->_esc_params($params,@unsafe) if $params;
    $u .= "?".$self->_esc_query($query,  @unsafe) if $query;
    $u .= "#".$self->_esc_frag($frag,    @unsafe) if $frag;
    return $u;
}


# Generic-RL: Resolving Relative URL into an Absolute URL
#
# Based on draft-ietf-uri-relative-url-06.txt Section 4
#
sub abs
{
    my($self, $base) = @_;
    my $embed = $self->clone;

    $base = $self->base unless $base;      # default to default base
    return $embed unless $base;            # we have no base (step1)

    $base = new URI::URL $base unless ref $base; # make obj if needed

    my($scheme, $host, $port, $path, $params, $query, $frag) =
        @{$embed}{qw(scheme host port path params query frag)};

    # just use base if we are empty             (2a)
    {
        my @u = grep(defined($_) && $_ ne '',
                     $scheme,$host,$port,$path,$params,$query,$frag);
        return $base->clone unless @u;
    }

    # if we have a scheme we must already be absolute   (2b)
    return $embed if $scheme;

    $embed->{'_str'} = '';                      # void cached string
    $embed->{scheme} = $base->{scheme};         # (2c)

    return $embed if $embed->{netloc};          # (3)
    $embed->{netloc} = $base->{netloc};         # (3)
    $embed->_read_netloc();

    return $embed if $path =~ m:^/:;            # (4)
    
    if ($path eq '') {                          # (5)
        $embed->{path} = $base->{path};         # (5)

        return $embed if $embed->params;        # (5a)
        $embed->{params} = $base->{params};     # (5a)

        return $embed if $embed->query;         # (5b)
        $embed->{query} = $base->{query};       # (5b)
        return $embed;
    }

    # (Step 6)  # draft 6 suggests stack based approach

    my $basepath = $base->{path};
    my $relpath  = $embed->{path};

    $basepath =~ s!^/!!;
    $basepath =~ s!/$!/.!;              # prevent empty segment
    my @path = split('/', $basepath);   # base path into segments
    pop(@path);                         # remove last segment

    $relpath =~ s!/$!/.!;               # prevent empty segment

    push(@path, split('/', $relpath));  # append relative segments

    my @newpath = ();
    my $isdir = 0;
    my $segment;

    foreach $segment (@path) {  # left to right
#       warn '> ', join('/', @newpath), ": $segment\n";
        if ($segment eq '.') {  # ignore "same" directory
            $isdir = 1;
        }
        elsif ($segment eq '..') {
            $isdir = 1;
            my $last = pop(@newpath);
            if (!defined $last) { # nothing to pop
                push(@newpath, $segment); # so must append
            }
            elsif ($last eq '..') { # '..' cannot match '..'
                # so put back again, and append
                push(@newpath, $last, $segment);
            }
            else {
                # it was a component, 
                # keep popped
            }
        } else {
            $isdir = 0;
            push(@newpath, $segment);
        }
    }

    $embed->{path} = join('/', @newpath) . ($isdir ? '/' : '');
    $embed;
}


# default_port()
#
# subclasses will usually want to override this
#
sub default_port {
    0;
}


####################################################################
#
#       Internal pre-defined basic scheme support

# Define the default ports for major net services 
# From RFC 1738 "Uniform Resource Locators (URL)"
# Note that other Well Known Port Numbers are defined in
# the "Assigned Numbers" RFC (1700).
# XXX the rfc1700 ones should arguably use getservbyname
# or be in a Etc/Services.pm or something


package URI::URL::file;         @ISA = qw(URI::URL::_generic);

# fileurl        = "file://" [ host | "localhost" ] "/" fpath
# fpath          = fsegment *[ "/" fsegment ]
# fsegment       = *[ uchar | "?" | ":" | "@" | "&" | "=" ]
# Note that fsegment can contain '?' (query) but not ';' (param)

sub _parse {
    my($self, $init) = @_;
    # allow the generic parser to do the bulk of the work
    $self->URI::URL::_generic::_parse($init);
    # then just deal with the effect of rare stray '?'s
    if (defined $self->{query}){
        $self->{path} .= '?' . $self->{query};
        delete $self->{query};
    }
    1;
}

sub _esc_path
{
    my($self, $text) = @_;
    $text =~ s/([^-a-zA-Z\d\$_.+!*'(),%?:@&=\/])/$escapes{$1}/oeg;
    $text;
}



package URI::URL::ftp;          @ISA = qw(URI::URL::_generic);

sub default_port { 21 };



package URI::URL::telnet;       @ISA = qw(URI::URL::_generic);

sub default_port { 23 };



package URI::URL::whois;        @ISA = qw(URI::URL::_generic);

sub default_port { 43 };



package URI::URL::gopher;       @ISA = qw(URI::URL::_generic);

sub default_port { 70 };

sub _parse {
    my($self, $url)   = @_;
    $self->{scheme}   = lc($1) if $url =~ s/^\s*([\w\+\.\-]+)://;
    $self->{netloc}   = $self->unescape($1) if $url =~ s!^//([^/]*)!!;
    $self->{gtype}    = $self->unescape($1) if $url =~ s!^/(.)!!;
    my @parts         = split(/%09/, $url, 3);
    $self->{selector} = $self->unescape(shift @parts);
    $self->{search}   = $self->unescape(shift @parts);
    $self->{string}   = $self->unescape(shift @parts);
}

sub gtype    { shift->elem('gtype', @_); }



package URI::URL::finger;       @ISA = qw(URI::URL::_generic);

sub default_port { 79 };



package URI::URL::http;         @ISA = qw(URI::URL::_generic);

sub default_port { 80 };



package URI::URL::nntp;         @ISA = qw(URI::URL::_generic);

sub default_port { 119 };

sub _parse {
    my($self, $init) = @_;
    $self->URI::URL::_generic::_parse($init);
    my @parts      = split(/\//, $self->{path});
    $self->{group} = $self->unescape($parts[1]);
    $self->{digits}= $self->unescape($parts[2]);
}



package URI::URL::news;         @ISA = qw(URI::URL::_generic);

sub _parse {
    my($self, $init) = @_;
    $self->{scheme}  = lc($1) if ($init =~ s/^\s*([\w\+\.\-]+)://);
    my $tmp = $self->unescape($init);
    $self->{grouppart} = $tmp;
    $self->{ ($tmp =~ m/\@/) ? 'article' : 'group' } = $tmp;
}



package URI::URL::wais;         @ISA = qw(URI::URL::_generic);

sub default_port { 210 };

sub _parse {
    my($self, $init) = @_;
    $self->URI::URL::_generic::_parse($init);
    my @parts         = split(/\//, $self->{'path'});
    $self->{database} = $self->unescape($parts[1]);
    $self->{wtype}    = $self->unescape($parts[2]);
    $self->{wpath}    = $self->unescape($parts[3]);
}



package URI::URL::webster;      @ISA = qw(URI::URL::_generic);

sub default_port { 765 };



package URI::URL::prospero;     @ISA = qw(URI::URL::_generic);

sub default_port { 1525 };      # says rfc1738, section 3.11



package URI::URL::mailto;       @ISA = qw(URI::URL::_generic);

sub _parse {
    my($self, $init) = @_;
    $self->{scheme}  = lc($1) if ($init =~ s/^\s*([\w\+\.\-]+)://);
    $self->{encoded822addr} = $self->unescape($init);
}



package URI::URL::rlogin;       @ISA = qw(URI::URL::_generic);



package URI::URL::tn3270;       @ISA = qw(URI::URL::_generic);



# Aliases for old method names. To be deleted in a future version.
{   package URI::URL::_generic;
    no strict qw(refs);
    *{"dump"} = \&print_on;
    *{"str"}  = \&as_string;
}



#####################################################################
#
# S E L F   T E S T   S E C T I O N
#
#####################################################################
#
# If we're not use'd or require'd execute self-test.
# Handy for regression testing and as a quick reference :)
#
# Test is kept behind __END__ so it doesn't take uptime
# and memory  unless explicitly required. If you're working
# on the code you might find it easier to comment out the
# eval and __END__ so that error line numbers make more sense.

package main;

eval join('',<DATA>) || die "$@ $DATA" unless caller();

1;

__END__


package URI::URL::_generic;

# _expect()
#
# Handy low-level object method tester. See test code at end.
#
sub _expect {
    my($self, $method, $expect, @args) = @_;
    my $result = $self->$method(@args);
    $expect = 'UNDEF' unless defined $expect;
    $result = 'UNDEF' unless defined $result;
    return 1 if $expect eq $result;
    warn "'$self'->$method(@args) = '$result' " .
                "(expected '$expect')\n";
    $self->print_on('STDERR');
    confess "Test Failed";
}


package main;

use Carp;
import URI::URL qw(uri_escape uri_unescape);
$| = 1;

# Do basic tests first.
# Dies if an error has been detected, prints "ok" otherwise.

print "Self tests for URI::URL version $URI::URL::Version...\n";

    &scheme_parse_test;

    &parts_test;

    &escape_test;

    &newlocal_test;

    &absolute_test;

    URI::URL::strict(0);
    $u = new URI::URL "myscheme:something";
    # print $u->as_string, " works after URI::URL::strict(0)\n";

print "URI::URL version $URI::URL::Version ok\n";
exit 0;




#####################################################################
#
# scheme_parse_test()
#
# test parsing and retrieval methods

sub scheme_parse_test {

    print "scheme_parse_test:\n";

    $tests = {
        'hTTp://web1.net/a/b/c/welcome#intro'
        => {    'scheme'=>'http', 'host'=>'web1.net', 'port'=>undef,
                'path'=>'/a/b/c/welcome', 'frag'=>'intro',
		'query'=>undef,
                'as_string'=>'http://web1.net/a/b/c/welcome#intro' },

        'http://web:1/a?query+text'
        => {    'scheme'=>'http', 'host'=>'web', 'port'=>1,
                'path'=>'/a', 'frag'=>undef, 'query'=>'query text' },

        'http://web.net'
        => {    'scheme'=>'http', 'host'=>'web.net', 'port'=>undef,
                'path'=>'', 'frag'=>undef, 'query'=>undef,
                'user'=>undef },

        'ftp://usr:pswd@web:1234/a/b;type=i'
        => {    'host'=>'web', 'port'=>1234, 'path'=>'/a/b',
                'user'=>'usr', 'password'=>'pswd',
                'params'=>'type=i',
                'as_string'=>'ftp://usr:pswd@web:1234/a/b;type=i' },

        'file://host/fseg/fs?g/fseg'
        # don't escape ? for file: scheme
        => {    'host'=>'host', 'path'=>'/fseg/fs?g/fseg',
                'as_string'=>'file://host/fseg/fs?g/fseg' },

        'gopher://web/2a_selector'
        => {    'gtype'=>'2', 'selector'=>'a_selector' },

        'mailto:libwww-perl@ics.uci.edu'
        => {    'encoded822addr'=>'libwww-perl@ics.uci.edu' },

        'news:*'                 
        => {    'grouppart'=>'*' },
        'news:comp.lang.perl' 
        => {    'group'=>'comp.lang.perl' },
        'news:perl-faq/module-list-1-794455075@ig.co.uk'
        => {    'article'=>
		    'perl-faq/module-list-1-794455075@ig.co.uk' },

        'nntp://news.com/comp.lang.perl/42'
        => {    'group'=>'comp.lang.perl', 'digits'=>42 },

        'telnet://usr:pswd@web:12345/'
        => {    'user'=>'usr', 'password'=>'pswd' },

        'wais://web.net/db'       
        => { 'database'=>'db' },
        'wais://web.net/db?query' 
        => { 'database'=>'db', 'query'=>'query' },
        'wais://usr:pswd@web.net/db/wt/wp'
        => {    'database'=>'db', 'wtype'=>'wt', 'wpath'=>'wp',
                'password'=>'pswd' },
    };

    foreach $url_str (sort keys %$tests ){
        warn "Testing '$url_str'\n";
        my $url = new URI::URL $url_str;
        my $tests = $tests->{$url_str};
        while( ($method, $exp) = each %$tests ){
            $exp = 'UNDEF' unless defined $exp;
            if ($method eq 'as_string'){
                $url->_expect('as_string', $exp);
            } else {
                $url->_expect('elem', $exp, $method);
            }
        }
    }
}


#####################################################################
#
# parts_test()          (calls netloc_test test)
#
# Test individual component part access functions
#
sub parts_test {
    print "parts_test:\n";

    # test storage part access/edit methods (netloc, user, password,
    # host and port are tested by &netloc_test)

    $url = new URI::URL 'file://web/orig/path';
    $url->scheme('http');
    $url->path('1info');
    # $url->query('key+word');	was wrong, + is 'escaped' form
    $url->query('key words');
    $url->frag('this');
    $url->_expect('as_string', 'http://web/1info?key+words#this');

    &netloc_test;
    &port_test;
		  
    $url->query(undef);
    $url->_expect('query', undef);
    $url->print_on;
}

#
# netloc_test()
#
# Test automatic netloc synchronisation
#
sub netloc_test {
    print "netloc_test:\n";

    my $url = new URI::URL 'http://anonymous:p%61ss@hst:12345';
    $url->_expect('user', 'anonymous');
    $url->_expect('password', 'pass');
    $url->_expect('host', 'hst');
    $url->_expect('port', 12345);
    $url->_expect('netloc', 'anonymous:pass@hst:12345');

    $url->user('nemo');
    $url->password('p2');
    $url->host('hst2');
    $url->port(2);
    $url->_expect('netloc', 'nemo:p2@hst2:2');

    $url->user(undef);
    $url->password(undef);
    $url->port(undef);
    $url->_expect('netloc', 'hst2');
}

#
# port_test()
#
# Test port behaviour
#
sub port_test {
    print "port_test:\n";

    $url = URI::URL->new('http://foo/root/dir/');
    my $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->as_string eq
	'http://foo/root/dir/';

    $url->port(8001);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 8001;
    die "Wrong string" unless $url->as_string eq 
	'http://foo:8001/root/dir/';

    $url->port(80);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->as_string eq 
	'http://foo/root/dir/';

    $url->port(8001);
    $url->port(undef);
    $port = $url->port;
    die "Port undefined" unless defined $port;
    die "Wrong port $port" unless $port == 80;
    die "Wrong string" unless $url->as_string eq 
	'http://foo/root/dir/';
}


#####################################################################
#
# escape_test()
#
# escaping functions

sub escape_test {
    print "escape_test:\n";

    # supply escaped URL
    $url = new URI::URL 'http://web/this%20has%20spaces';
    # check component is unescaped
    $url->_expect('path', '/this has spaces');

    # modify the unescaped form
    $url->path('this ALSO has spaces');
    # check whole url is escaped
    $url->_expect('as_string',
		  'http://web/this%20ALSO%20has%20spaces');

    # now make 'A' an unsafe character :-)
    $url->unsafe('A\x00-\x20"#%;<>?\x7F-\xFF');
    $url->_expect('as_string',
		  'http://web/this%20%41LSO%20has%20spaces');

    $url = new URI::URL uri_escape('http://web/try %?#" those');
    $url->_expect('as_string', 
		  'http://web/try%20%25%3F%23%22%20those');

    my $all = pack('c*',0..255);
    my $esc = uri_escape($all);
    my $new = uri_unescape($esc);
    die "uri_escape->uri_unescape mismatch" unless $all eq $new;

    # test escaping uses uppercase (preferred by rfc1837)

    $url = new URI::URL 'file://h/';
    $url->path(chr(0x7F));
    $url->_expect('as_string', 'file://h/%7F');

    # reserved characters differ per scheme

##  XXX is this '?' allowed to be unescaped
    $url = new URI::URL 'file://h/test?ing';
    $url->_expect('path', '/test?ing');

    $url = new URI::URL 'file://h/';
    $url->path('question?mark');
    $url->_expect('as_string', 'file://h/question?mark');

    # need more tests here
}


#####################################################################
#
# newlocal_test()
#

sub newlocal_test {
    print "newlocal_test:\n";

    my $dir = Cwd::fastcwd();

    # cwd
    chdir('/tmp') or die $!;
    $url = newlocal URI::URL;
    $url->_expect('as_string', 'file://localhost/tmp/');

    # absolute dir
    chdir('/') or die $!;
    $url = newlocal URI::URL '/usr/';
    $url->_expect('as_string', 'file://localhost/usr/');

    # absolute file
    $url = newlocal URI::URL '/vmunix';
    $url->_expect('as_string', 'file://localhost/vmunix');

    # relative file
    chdir('/tmp') or die $!;
    $url = newlocal URI::URL 'foo';
    $url->_expect('as_string', 'file://localhost/tmp/foo');

    # relative dir
    chdir('/tmp') or die $!;
    $url = newlocal URI::URL 'bar/';
    $url->_expect('as_string', 'file://localhost/tmp/bar/');

    # 0
    chdir('/') or die $!;
    $url = newlocal URI::URL '0';
    $url->_expect('as_string', 'file://localhost/0');

    chdir($dir) or die $!;
}


#####################################################################
#
# absolute_test()
#
sub absolute_test {

    print "Test relative/absolute URI::URL parsing:\n";

    # Tests from draft-ietf-uri-relative-url-06.txt
    # Copied verbatim from the draft, parsed below

    @URI::URL::g::ISA = qw(URI::URL::_generic); # for these tests

    my $base = 'http://a/b/c/d;p?q#f';

    $absolute_tests = <<EOM;
5.1.  Normal Examples

      g:h        = <URL:g:h>
      g          = <URL:http://a/b/c/g>
      ./g        = <URL:http://a/b/c/g>
      g/         = <URL:http://a/b/c/g/>
      /g         = <URL:http://a/g>
      //g        = <URL:http://g>
      ?y         = <URL:http://a/b/c/d;p?y>
      g?y        = <URL:http://a/b/c/g?y>
      g?y/./x    = <URL:http://a/b/c/g?y/./x>
      #s         = <URL:http://a/b/c/d;p?q#s>
      g#s        = <URL:http://a/b/c/g#s>
      g#s/./x    = <URL:http://a/b/c/g#s/./x>
      g?y#s      = <URL:http://a/b/c/g?y#s>
      ;x         = <URL:http://a/b/c/d;x>
      g;x        = <URL:http://a/b/c/g;x>
      g;x?y#s    = <URL:http://a/b/c/g;x?y#s>
      .          = <URL:http://a/b/c/>
      ./         = <URL:http://a/b/c/>
      ..         = <URL:http://a/b/>
      ../        = <URL:http://a/b/>
      ../g       = <URL:http://a/b/g>
      ../..      = <URL:http://a/>
      ../../     = <URL:http://a/>
      ../../g    = <URL:http://a/g>

5.2.  Abnormal Examples

   Although the following abnormal examples are unlikely to occur
   in normal practice, all URL parsers should be capable of resolving
   them consistently.  Each example uses the same base as above.

   An empty reference resolves to the complete base URL:

      <>         = <URL:http://a/b/c/d;p?q#f>

   Parsers must be careful in handling the case where there are more
   relative path ".." segments than there are hierarchical levels in
   the base URL's path.  Note that the ".." syntax cannot be used to
   change the <net_loc> of a URL.

     ../../../g = <URL:http://a/../g>
     ../../../../g = <URL:http://a/../../g>

   Similarly, parsers must avoid treating "." and ".." as special
   when they are not complete components of a relative path.

      /./g       = <URL:http://a/./g>
      /../g      = <URL:http://a/../g>
      g.         = <URL:http://a/b/c/g.>
      .g         = <URL:http://a/b/c/.g>
      g..        = <URL:http://a/b/c/g..>
      ..g        = <URL:http://a/b/c/..g>

   Less likely are cases where the relative URL uses unnecessary or
   nonsensical forms of the "." and ".." complete path segments.

      ./../g     = <URL:http://a/b/g>
      ./g/.      = <URL:http://a/b/c/g/>
      g/./h      = <URL:http://a/b/c/g/h>
      g/../h     = <URL:http://a/b/c/h>

   Finally, some older parsers allow the scheme name to be present in
   a relative URL if it is the same as the base URL scheme.  This is
   considered to be a loophole in prior specifications of partial
   URLs [1] and should be avoided by future parsers.

      http:g     = <URL:http:g>
      http:      = <URL:http:>
EOM
    # convert text to list like
    # @absolute_tests = ( ['g:h' => 'g:h'], ...)

    for $line (split("\n", $absolute_tests)) {
        next unless $line =~ /^\s{6}/;
        if ($line =~ /^\s+(\S+)\s*=\s*<URL:([^>]*)>/) {
            my($rel, $abs) = ($1, $2);
            $rel = '' if $rel eq '<>';
            push(@absolute_tests, [$rel, $abs]);
        }
        else {
            warn "illegal line '$line'";
        }
    }

    # add some extra ones for good measure

    push(@absolute_tests, ['x/y//../z' => 'http://a/b/c/x/y/z'],
                          ['1'         => 'http://a/b/c/1'    ],
                          ['0'         => 'http://a/b/c/0'    ],
                          ['/0'        => 'http://a/0'        ],
        );

    print "  Relative    +  Base  =>  Expected Absolute URL\n";
    print "================================================\n";
    for $test (@absolute_tests) {
        my($rel, $abs) = @$test;
        my $abs_url = new URI::URL $abs;
        my $abs_str = $abs_url->as_string;

        printf("  %-10s  +  $base  =>  $abs\n", $rel);
        my $u   = new URI::URL $rel, $base;
        my $got = $u->abs;
        $got->_expect('as_string', $abs_str);
    }
    print "absolute test ok\n";
}
