#
# $Id: URL.pm,v 3.10 1995/09/15 17:03:33 aas Exp $
#
package URI::URL;
require 5.001;  # but it should really be 5.001e

# Make the version number available
$VERSION = "3.05";
sub Version { $VERSION; }

#####################################################################

=head1 NAME

URI::URL - Uniform Resource Locators (absolute and relative)

=head1 SYNOPSIS

 require URI::URL;

 # Constructors
 $url1 = new URI::URL 'http://www.perl.com/%7Euser/gisle.gif';
 $url2 = new URI::URL 'gisle.gif', 'http://www.com/%7Euser';
 $url3 = $url2->abs; # get absolute url using base
 $url4 = $url2->abs('http:/other/path');

 $url5 = newlocal URI::URL;                # pwd
 $url6 = newlocal URI::URL '/tmp';         # dir
 $url7 = newlocal URI::URL '/etc/motd';    # file

 $url  = $url8->clone;     # copy objects

 # Stringify URL
 $str1 = $url->as_string;  # complete escaped URL string
 $str2 = $url->full_path;  # escaped path+query+params
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

 # All methods above can set field values:
 $url->scheme('http');
 $url->host('www.w3.org');
 $url->port($url->default_port);
 $url->base($url5);          # use string or object

 # Specify unsafe characters to be escaped for this url
 $url->unsafe('\x00-\x20"\$#%;<>?\x7E-\xFF');

 # Port numbers
 $defport= $url->default_port;  # default port for scheme

 # Functions
 URI::URL::strict(0);                    # disable strict schemes
 URI::URL::implementor;                  # get generic implementor
 URI::URL::implementor($scheme);         # get scheme implementor
 URI::URL::implementor($scheme, $class); # set scheme implementor

=head1 DESCRIPTION

This module implements URI::URL objects representing Uniform Resource
Locators (URL). Both absolute (RFC 1738) and relative (RFC 1808) URLs
are supported.

URI::URL objects are created by C<new()>, which takes a string
representation of a URL or an existing URL object reference to be
cloned. Specific individual elements can then be accessed via the
C<scheme()>, C<user()>, C<password()>, C<host()>, C<port()>,
C<path()>, C<params()>, C<query()> and C<frag()> methods. These
methods can be called with a value to set the element to that value,
and always return the old value. The C<elem()> method provides a
general interface to access any element by name but it should be used
with caution: the effect of using incorrect spelling and case is
undefined.

The C<abs()> method attempts to return a new absolute URI::URL object
for a given URL.  In order to convert a relative URL into an absolute
one a I<base> URL is required. You can associate a default base with a
URL either by passing a I<base> to the C<new()> constructor when a
URI::URL is created or using the C<base()> method on the object later.
Alternatively you can specify a one-off base as a parameter to the
C<abs()> method.

The object constructor C<new()> must be able to determine the scheme
for the URL.  If a scheme is not specified in the URL it will use the
scheme specified by the base URL. If no base URL scheme is defined
then C<new()> will croak unless URI::URL::strict(0) has been
invoked, in which case I<http> is silently assumed.

Once the scheme has been determined C<new()> then uses the
C<implementor()> function to determine which class implements that
scheme.  If no implementor class is defined for the scheme then
C<new()> will croak unless URI::URL::strict(0) has been invoked, in
which case the internal generic class is assumed.

Internally defined schemes are implemented by C<URI::URL::scheme_name>.
The C<URI::URL::implementor()> function can also be used to set the class
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
components. Complete URLs are always escaped.

The components of a URL string must be I<individually> escaped.  Each
component of a URL may have a separate requirements regarding what
must be escaped, and those requirements are also dependent on the URL
scheme.

Never escape an already escaped component string.

=back

This implementation expects an escaped URL string to be passed to
C<new()> and will return an escaped URL string from C<as_string()>.
Individual components must be manipulated in unescaped form (this is
most natural anyway).

The escaping applied to a URL when it is constructed by C<as_string()>
(or C<full_path()>) can be controlled by using the C<unsafe()> method
to specify which characters should be treated as unsafe.


=head1 ADDING NEW URL SCHEMES

New URL schemes or alternative implementations for existing schemes
can be added to your own code. To create a new scheme class use code
like:

   package MYURL::foo;              
   @ISA = (URI::URL::implementor);   # inherit from generic scheme

The 'URI::URL::implementor()' function call with no parameters returns
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
(especially for interpolating URLs into strings) but should not yet
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

Copyright (c) 1995 Gisle Aas. All rights reserved.
Copyright (c) 1995 Martijn Koster. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

IN NO EVENT SHALL THE AUTHORS BE LIABLE TO ANY PARTY FOR DIRECT,
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION (INCLUDING, BUT NOT
LIMITED TO, LOST PROFITS) EVEN IF THE AUTHORS HAVE BEEN ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE. 

=head1 PREREQUISITES

You will need Perl5.001e or better.

=head1 AVAILABILITY

The latest version of this module is likely to be available from:

   http://www.oslonett.no/home/aas/perl/www/
   http://web.nexor.co.uk/public/perl/perl.html
   http://www.ics.uci.edu/WebSoft/libwww-perl/contrib/

=head1 BUGS

Not all schemes are fully implemented. Two-way functions
to get/set things like the News URL digits etc. are missing.

Non-http scheme specific escaping is not correct yet.

=head1 METHODS AND FUNCTIONS

=cut

#####################################################################


require Carp;
require URI::Escape;

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


$Debug = 0;             # set to 1 to print URLs on creation
my $UseCache = 1;       # see as_string method
my $StrictSchemes = 1;  # see new()

# schemes we have initialised:
my %ImplementedBy = ( '_generic' => 'URI::URL::_generic' );
# clases we have initialised:
my $Implementors  = ();

use strict qw(subs refs);


#####################################################################
#
# URI::URL objects are implemented as blessed hashes:
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

or set C<URI::URL::strict(0)> if you do not care about bad or unknown
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
        $init = "" unless defined $init;
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
            Carp::croak("Unable to determine scheme for '$init'")
                if $StrictSchemes;
            $scheme = 'http';
        }
        my $impclass = URI::URL::implementor($scheme);
        unless ($impclass) {
            Carp::croak("URI::URL scheme '$scheme' is not supported")
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
    # this work as long as none of the components are references themselves
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
    my $url = new URI::URL "file:";
        
    unless (defined $path and $path =~ m:^/:) {
        require Cwd;
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
    return $ic if $ic = $ImplementedBy{$scheme};

    # scheme not yet known, look for internal or
    # preloaded (with 'use') implementation
    $ic = "URI::URL::$scheme";  # default location
    no strict qw(refs);
    # check we actually have one for the scheme:
    unless (defined @{"${ic}::ISA"}) {
	# Try to load it
	eval { require "URI/URL/$scheme.pm"; };
	$ic = '' unless defined @{"${ic}::ISA"};
    }
    if ($ic) {
        $ic->_init_implementor;
        $ImplementedBy{$scheme} = $ic;
    }
    $ic;
}


sub _init_implementor                   # private method
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
    1;  # success, one day we may also want to indicate failure
}


# This private method help us implement access to the elements in the
# URI::URL object hash (%$self).  You can set up access to an element
# with a routine similar to this one:
#
#  sub component { shift->_elem('component', @_); }
#

sub _elem {
    my($self, $element, @val) = @_;
    my $old = $self->{$element};
    return $old unless @val;
    $self->{$element} = $val[0]; # general case
    $self->{'_str'} = '';        # void cached string
    return $old;
}

# Access some attributes of a URL object:
sub base {
    my $self = shift;
    return $self->_elem('_base', @_) if @_;      # set
    # The base attribute supports 'lazy' conversion from URL strings
    # to URL objects. Strings may be stored but when a string is
    # fetched it will automatically be converted to a URL object.
    # The main benefit is to make it much cheaper to say:
    #   new URI::URL $random_url_string 'http:'
    my $base = $self->_elem('_base');            # get
    return undef unless defined $base;
    unless (ref $base){
        $base = new URI::URL $base;
        $self->_elem('_base', $base); # set new object
    }
    $base;
}

sub unsafe {
    shift->_elem('_unsafe', @_);
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
    my $self = shift;
    URI::Escape::uri_escape(@_);
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
    $text =~ s/ /+/g;   # RFC1630
    my $text = $self->escape($text, @unsafe);
}


sub unescape
{
    my $self = shift;
    URI::Escape::uri_unescape(@_);
}

# We don't bother defining method aliases for unescape because
# unescape does not need such fine control.



#####################################################################
#
#       Internal pre-defined generic scheme support
#
# In this implementation all schemes are subclassed from
# URI::URL::_generic. This turns out to have reasonable mileage.
# See also draft-ietf-uri-relative-url-06.txt

package URI::URL::_generic;           # base support for generic-RL's
@ISA = qw(URI::URL);

%OVERLOAD = ( '""'=>'as_string', 'fallback'=>1 );      # EXPERIMENTAL

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
    $self->{'frag'}   = $self->unescape($1) if $u =~ s/#(.*)$//;
    # 2.4.2
    $self->{'scheme'} = lc($1)   if $u =~ s/^\s*([\w\+\.\-]+)://;
    # 2.4.3
    $self->netloc($self->unescape($1)) if $u =~ s!^//([^/]*)!!;
    # 2.4.4
    if ($u =~ s/\?(.*)//){      # '+' -> ' ' for queries (RFC1630)
        my $query = $1;
        $query =~ s/\+/ /g;
        $self->{'query'}  = $self->unescape($query)
    }
    # 2.4.5
    $self->{'params'} = $self->unescape($1) if $u =~ s/;(.*)//;
    # 2.4.6
    #
    # RFC 1738 says: 
    #
    #     Note that the "/" between the host (or port) and the 
    #     url-path is NOT part of the url-path.
    #
    # however, RFC 1808, 2.4.6. says:
    #
    #    Even though the initial slash is not part of the URL path,
    #    the parser must remember whether or not it was present so 
    #    that later processes can differentiate between relative 
    #    and absolute paths.  Often this is done by simply storing
    #    he preceding slash along with the path.
    # 
    # so we'll store it in $self->{path}, and strip it when asked
    # for $self->path()

    $self->{'path'}   = $self->unescape($u);
    1;
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

    # full_path() -> /path+query+params (escaped)
    my $path = $self->full_path(@unsafe);
    my $frag = $self->{'frag'};
    $path .= "#".$self->_esc_frag($frag, @unsafe) if $frag;    

    if ($netloc){
        $path = "//".$self->_esc_netloc($netloc, @unsafe).$path;
    }
    my $urlstr = ($scheme) ? "$scheme:$path" : $path;
    $self->{'_str'} = $urlstr;  # set cache
    return $urlstr;
}

# Generic-RL stringify full path (path+query+params)
#
sub full_path
{
    my $self = shift;
    # use @ here to avoid undef warnings and allow $self->escape
    # to use optimised pattern if no override has been set.
    my @unsafe = shift || $self->unsafe || ();
    my($path, $params, $query)
        = @{$self}{ qw(path params query) };
    my $u = '';
    $u .=     $self->_esc_path($path,    @unsafe) if $path;
    $u = "/$u" unless $u =~ m:^/:; # see comment in _parse 2.4.6
    $u .= ";".$self->_esc_params($params,@unsafe) if $params;
    $u .= "?".$self->_esc_query($query,  @unsafe) if $query;

    # rfc 1808 says:
    #    Note that the fragment identifier (and the "#" that precedes 
    #    it) is not considered part of the URL.  However, since it is
    #    commonly used within the same string context as a URL, a parser
    #    must be able to recognize the fragment when it is present and 
    #    set it aside as part of the parsing process.
    # so we'll leave the fragment off

    return $u;
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
sub scheme;  # defined below
sub netloc;  # defined below
sub path;    # defined below
sub params   { shift->_elem('params',  @_); }
sub query    { shift->_elem('query',   @_); }
sub frag     { shift->_elem('frag',    @_); }

# Fields derived from generic netloc:
sub user     { shift->_netloc_elem('user',    @_); }
sub password { shift->_netloc_elem('password',@_); }
sub host     { shift->_netloc_elem('host',    @_); }
sub port;    # defined below


# Field that need special treatment
sub scheme {
    my $self = shift;
    my $old = $self->{'scheme'};
    return $old unless @_;
    my $newscheme = shift;

    if (defined($newscheme) && length($newscheme)) {
	# reparse URL with new scheme
	my $str = $self->as_string;
	$str =~ s/^[\w+\-.]+://;
	my $newself = new URI::URL "$newscheme:$str";
	%$self = %$newself;
	bless $self, ref($newself);
    } else {
	$self->{'scheme'} = $newscheme;
    }
    $old;
}

sub netloc {
    my $self = shift;
    my $old = $self->_elem('netloc', @_);
    return $old unless @_;

    # update fields derived from netloc
    my $nl = $self->{'netloc'} || ''; # already unescaped
    if ($nl =~ s/^([^:@]*):?(.*?)@//){
        $self->{'user'}     = $1;
        $self->{'password'} = $2 if $2 ne '';
    }
    if ($nl =~ s/^([^:]*):?(\d*)//){
        $self->{'host'} = $1;
	if ($2 ne '') {
	    $self->{'port'} = $2;
	    if ($2 == $self->default_port) {
		$self->{'netloc'} =~ s/:\d+//;
	    }
	}
    }
    $old;
}

sub path {
     my $old = shift->_elem('path', @_);
     $old =~ s!^/!! if defined $old;
     $old;
}

sub port {
    my $self = shift;
    my $old = $self->_netloc_elem('port', @_);
    $old || $self->default_port;
}

sub _netloc_elem {
    my($self, $elem, @val) = @_;
    my $old = $self->_elem($elem, @val);
    return $old unless @val;

    # update the 'netloc' element
    my $tmp;
    my $nl = $self->{'user'} || '';
    $nl .= ":$self->{'password'}" if $nl and $self->{'password'};
    $nl .= '@' if $nl;
    $nl .= ($tmp = $self->{'host'});
    $nl .= ":$tmp" if ($tmp && ($tmp=$self->{'port'})
                            && $tmp != $self->default_port);
    $self->{'netloc'} = $nl;

    $old;
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
    $embed->{'scheme'} = $base->{'scheme'};     # (2c)

    return $embed if $embed->{'netloc'};        # (3)
    $embed->netloc($base->{'netloc'});          # (3)

    return $embed if $path =~ m:^/:;            # (4)
    
    if ($path eq '') {                          # (5)
        $embed->{'path'} = $base->{'path'};     # (5)

        return $embed if $embed->params;        # (5a)
        $embed->{'params'} = $base->{'params'}; # (5a)

        return $embed if $embed->query;         # (5b)
        $embed->{'query'} = $base->{'query'};   # (5b)
        return $embed;
    }

    # (Step 6)  # draft 6 suggests stack based approach

    my $basepath = $base->{'path'};
    my $relpath  = $embed->{'path'};

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

    $embed->{'path'} = '/' . join('/', @newpath) . 
        ($isdir && @newpath ? '/' : '');

    $embed;
}


# default_port()
#
# subclasses will usually want to override this
#
sub default_port {
    0;
}


# The only scheme that is always loaded is http.

package URI::URL::http;
@ISA = qw(URI::URL::_generic);

sub default_port { 80 }

sub illegal { Carp::croak("Illegal method for http URLs"); }
*user     = \&illegal;
*password = \&illegal;

1;
