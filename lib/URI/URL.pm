#
# $Id: URL.pm,v 4.0 1996/02/05 17:51:37 aas Exp $
#
package URI::URL;
require 5.002;

# Make the version number available
$VERSION = "4.00";
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
 $str2 = $url->full_path;  # escaped path+params+query
 $str3 = "$url";           # use operator overloading

 # Retrieving Generic-RL components:
 $scheme   = $url->scheme;
 $netloc   = $url->netloc;  # see user,password,host,port below
 $path     = $url->path;
 $params   = $url->params;
 $query    = $url->query;
 $frag     = $url->frag;

 # Accessing elements in their escaped form
 $path     = $url->epath;
 $params   = $url->eparams;
 $query    = $url->equery;

 # Retrieving Network location (netloc) components:
 $user     = $url->user;
 $password = $url->password;
 $host     = $url->host;
 $port     = $url->port;     # returns default if not defined

 # Retrieve escaped path components as an array
 @path     = $url->path_components;

 # HTTP query-string access methods
 @keywords = $url->keywords;
 @form     = $url->query_form;

 # Retrieving other attributes:
 $base     = $url->base;

 # All methods above can set the field values, e.g:
 $url->scheme('http');
 $url->host('www.w3.org');
 $url->port($url->default_port);
 $url->base($url5);          # use string or object
 $url->keywords(qw(dog bones));

 # Is this path an absolute one (anchored by a leading "/")
 $bool     = $url->absolute_path;          

 # File methods
 $url = new URI::URL "file:/foo/bar";
 $file  = $url->local_path;
 # or you can be explicit about which kind of system you want a path for
 $ufile = $url->unix_path;
 $mfile = $url->mac_path;
 $dfile = $url->dos_path;
 $vfile = $url->vms_path;

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

URI::URL objects are created by new(), which takes a string
representation of a URL or an existing URL object reference to be
cloned. Specific individual elements can then be accessed via the
scheme(), user(), password(), host(), port(), path(), params(),
query() and frag() methods. These methods can be called with an
argument to set the element to that value, and they always return the
old value.  Note that not all URL schemes will support all these
methods.

In addition you might access escaped versions of the path, params and
query with the epath(), eparams() and equery() methods.  The path can
also be accessed using the path_components() method which will return
the path as a list of unescaped path components.

For http:-URLs you may also access the query() using the keywords() and the
query_form() methods.  The keywords() method returns a list of unescaped
strings.  The query_form() method return a list of unescaped key/value
pairs.  Both will croak if the query is not of the correct format.

The file:-URLs implement the local_path() method that returns a path
suitable for accessing the current filesystem.

The abs() method attempts to return a new absolute URI::URL object
for a given URL.  In order to convert a relative URL into an absolute
one, a I<base> URL is required. You can associate a default base with a
URL either by passing a I<base> to the new() constructor when a
URI::URL is created or using the base() method on the object later.
Alternatively you can specify a one-off base as a parameter to the
abs() method.

The object constructor new() must be able to determine the scheme
for the URL.  If a scheme is not specified in the URL it will use the
scheme specified by the base URL. If no base URL scheme is defined
then new() will croak unless URI::URL::strict(0) has been
invoked, in which case I<http> is silently assumed.

Once the scheme has been determined new() then uses the
implementor() function to determine which class implements that
scheme.  If no implementor class is defined for the scheme then
new() will croak unless URI::URL::strict(0) has been invoked, in
which case the internal generic class is assumed.

Internally defined schemes are implemented by the
URI::URL::I<scheme_name> module.  The URI::URL::implementor() function
can be used to explicitly set the class used to implement a scheme.


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
new() and will return a fully escaped URL string from as_string()
and full_path().

Individual components can be manipulated in unescaped or escaped
form. The following methods return/accept unescaped strings:

    scheme                  path
    user                    params
    password                query
    host                    frag
    port

The following methods return/accept partical I<escaped> strings:

    netloc                  eparams
    epath                   equery

I<Partial escaped> means that only reserved characters
(i.e. ':', '@', '/', ';', '?', '=', '&' in addition to '%', '.' and '#')
needs to be escaped when they are to be treated as normal characters.

=head1 ADDING NEW URL SCHEMES

New URL schemes or alternative implementations for existing schemes
can be added to your own code. To create a new scheme class use code
like:

   package MYURL::foo;              
   @ISA = (URI::URL::implementor());   # inherit from generic scheme

The 'URI::URL::implementor()' function call with no parameters returns
the name of the class which implements the generic URL scheme
behaviour (typically C<URI::URL::_generic>). All hierarchial schemes
should be derived from this class.

Your class can then define overriding methods (e.g., new(),
_parse() as required).

To register your new class as the implementor for a specific scheme
use code like:

   URI::URL::implementor('x-foo', 'MYURL::foo');

Any new URL created for scheme 'x-foo' will be implemented by your
C<MYURL::foo> class. Existing URLs will not be affected.


=head1 WHAT A URL IS NOT

URL objects do not, and should not, know how to 'get' or 'put' the
resources they specify locations for, anymore than a postal address
'knows' anything about the postal system. The actual access/transfer
should be achieved by some form of transport agent class. The agent
class can use the URL class, but should not be a subclass of it.

=head1 COMPATIBILITY

This is a listing incompatabilites with URI::URL version 3.x:

=over 3

=item unsafe(), escape() and unescape()

These methods not supported any more.

=item full_path() and as_string()

These methods does no longer take a second argument which specify the
set of characters to consider as unsafe.

=item '+' in the query-string

The '+' character in the query part of the URL was earlier considered
to be an encoding of a space. This was just bad influence from Mosaic.
Space is now encoded as '%20'.

=item path() and query()

This methods will croak if they loose information.  Use epath() or
equery() instead.  The path() method loose information if any path
segment contain an (encoded) '/' character.

=item netloc()

The string passed to netloc is now assumed to be escaped.  The string
returned will also be (partially) escaped.

=item sub-classing

The path, params and query is now stored internally in unescaped form.
This might affect sub-classes of the URL scheme classes.

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

This module is (distantly) based on the C<wwwurl.pl> code in the
libwww-perl distribution developed by Roy Fielding
<fielding@ics.uci.edu>, as part of the Arcadia project at the
University of California, Irvine, with contributions from Brooks
Cutter.

Gisle Aas <aas@sn.no>, Tim Bunce <Tim.Bunce@ig.co.uk>, Roy Fielding
<fielding@ics.uci.edu> and Martijn Koster <m.koster@webcrawler.com>
(in english(!!) alphabetical order) have collaborated on the complete
rewrite for Perl 5, with input from other people on the libwww-perl
mailing list.

If you have any suggestions, bug reports, fixes, or enhancements, send
them to the libwww-perl mailing list at <libwww-perl@ics.uci.edu>.

=head1 COPYRIGHT

Copyright (c) 1995, 1996 Gisle Aas. All rights reserved.
Copyright (c) 1995 Martijn Koster. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 METHODS AND FUNCTIONS

=cut

#####################################################################


require Carp;
require URI::Escape;

# Basic lexical elements, taken from RFC 1738:
#
# safe         = "$" | "-" | "_" | "." | "+"
# extra        = "!" | "*" | "'" | "(" | ")" | ","
# national     = "{" | "}" | "|" | "\" | "^" | "~" | "[" | "]" | "`"
# punctuation  = "<" | ">" | "#" | "%" | <">
# reserved     = ";" | "/" | "?" | ":" | "@" | "&" | "="
# escape       = "%" hex hex
# unreserved   = alpha | digit | safe | extra
# uchar        = unreserved | escape
# xchar        = unreserved | reserved | escape

# Avoid warnings (XXX fix this with 'use vars' when I get a newer perl)
$reserved = $reserved_no_slash = $reserved_no_form = undef;

# RFC 1738 reserved in addition to '#' and '%'
$reserved = ";\\/?:\\@&=#%";
$reserved_no_slash = ";?:\\@&=#%";  # used when escaping path
$reserved_no_form  = ";\\/?:\\@#%"; # used when escaping params and query

# This is the unsafe characters (not including those reserved)
$unsafe   = "\x00-\x20{}|\\\\^\\[\\]`<>\"\x7F-\xFF";
#$unsafe .= "~";  # according to RFC1738 but not to common practice

$Debug = 0;             # set to 1 to print URLs on creation
my $UseCache = 1;       # see as_string method
my $StrictSchemes = 1;  # see new()

# schemes we have initialised:
my %ImplementedBy = ( '_generic' => 'URI::URL::_generic' );
my %Implementors  = (); # clases we have initialised:

use strict qw(subs refs);


#####################################################################
#
# URI::URL objects are implemented as blessed hashes:
#

# Each of the URL components (scheme, netloc, user, password, host,
# port, path, params, query, fragment) are stored under their
# name. The netloc, path, params and query is stored in quoted
# (escaped) form.  The others is stored unquoted (unescaped).
#
# Netloc is special since it is rendundant (same as
# "user:password@host:port") and must be kept in sync with those.
#
# The '_str' key stores a cached stringified version of the URL
# (by definition in quoted form).
# The '_base' key stores the optional base of a relative URL.
#
# The '_orig_url' is used while debugging is on.
#
# Subclasses may add their own keys but must take great care to
# avoid names which might be used in later verions of this module.

# methods/functions

=head2 new

 $url = new URI::URL 'URL_string' [, $optional_base_url]

This is the object constructor.  It will create a new URI::URL object,
initialized from the URL string.  To trap bad or unknown URL schemes
use:

 $obj = eval { new URI::URL "snews:comp.lang.perl" };

or set URI::URL::strict(0) if you do not care about bad or unknown
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
	# RFC 1738 appendix suggest that we just ignore extra whitespace
        $init =~ s/\s+//g;
	# Also get rid of any <URL:> wrapper
	$init =~ s/^<URL:(.*)>$/$1/;

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
	$self->{'_orig_url'} = $init if $Debug;
        $self = $impclass->new($init, $base);
    }
    $self->print_on('STDERR') if $Debug;
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

Returns an URL object that denotes a path on the local filesystem
(current directory by default).  Paths not starting with '/' are
taken relative to the current directory.

=cut

sub newlocal
{
    require URI::URL::file;
    my($class, $path) = @_;
    newlocal URI::URL::file $path;  # pass it on the the file class
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

=head2 URI::URL::strict($bool)

If strict is true then we croak on errors.  The function returns the
previous value.

=cut

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
	Carp::carp($@) if $@ && $StrictSchemes;
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
    $old;
}

# Access some attributes of a URL object:
sub base {
    my $self = shift;
    return $self->_elem('_base', @_) if @_;      # set

    # The base attribute supports 'lazy' conversion from URL strings
    # to URL objects. Strings may be stored but when a string is
    # fetched it will automatically be converted to a URL object.
    # The main benefit is to make it much cheaper to say:
    #   new URI::URL $random_url_string, 'http:'
    my $base = $self->_elem('_base');            # get
    return undef unless defined $base;
    unless (ref $base){
        $base = new URI::URL $base;
        $self->_elem('_base', $base); # set new object
    }
    $base;
}

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
	$self->{'scheme'} = undef;
    }
    $old;
}

# These are just supported for some kind of backwards portability.

sub unsafe {
    Carp::croak("The unsafe() method not supported by URI::URL any more!
If you need this feature badly, then you should make a subclass of
the URL-schemes you need to modify the behavior for.  The method
was called");
}

sub escape
{
    Carp::croak("The escape() method not supported by URI::URL any more!
Use the URI::Escape module instead.  The method was called at");
}

sub unescape
{
    Carp::croak("unescape() method not supported by URI::URL any more!
Use the URI::Escape module instead.  The method was called at");
}

1;
