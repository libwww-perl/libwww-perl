#
# $Id: LWP.pm,v 1.24 1996/03/18 17:50:58 aas Exp $

package LWP;

$VERSION = "0.11";

sub Version { $VERSION; }

require 5.002;
require LWP::UserAgent;  # this should load everything you need

1;

__END__

=head1 NAME

LWP - Library for WWW access in Perl

=head1 DESCRIPTION

Libwww-perl is a collection of Perl modules which provides a simple
and consistent programming interface (API) to the World-Wide Web.  The
main focus of the library is to provide functions that allow you to
write WWW clients, thus libwww-perl said to be a WWW client
library. The library also contain modules that are of more general
use.

The main architecture of the library is object oriented.  The user
agent, requests sent and responses received from the WWW server are
all represented by objects.  This makes a simple and powerful
interface to these services.  The interface should be easy to extend
and customize for your needs.

The main features of the library are:

=over 3

=item *

Contains various reuseable components (modules) that can be
used separately or together.

=item *

Provides an object oriented model of HTTP-style communication.  Within
this framework we currently support access to http, gopher, ftp, file,
and mailto resources.

=item * 

The library be used through the full object oriented interface or
through a very simple procedural interface.

=item *

Support the basic and digest authorization schemes.

=item *

Transparent redirect handling

=item *

Supports access through proxy servers

=item *

URL handling (both absolute and relative)

=item *

A parser for robots.txt files and a framework for constructing robots.

=item *

An experimental HTML parser and formatter (PS and plain text)

=item *

The library can cooperate with Tk.  A simple Tk-based GUI browser is
distributed with the Tk extention for perl.

=item *

An implementation of the HTTP content negotiation algorithm that can
be used both in protocol modules and in server script (for instance
CGI).

=item *

A simple command line client application that is called
C<lwp-request>.

=back

=head1 HTTP STYLE COMMUNICATION


The libwww-perl library is based on HTTP style communication. What
does that mean? This is a quote from the HTTP specification document
<URL:http://www.w3.org/pub/WWW/Protocols/>:

=over 3

=item *

The HTTP protocol is based on a request/response paradigm. A client
establishes a connection with a server and sends a request to the
server in the form of a request method, URI, and protocol version,
followed by a MIME-like message containing request modifiers, client
information, and possible body content. The server responds with a
status line, including the message's protocol version and a success or
error code, followed by a MIME-like message containing server
information, entity metainformation, and possible body content.

=back

What this means to libwww-perl is that communcation always take
place by creating and configuring a I<request> object. This
object is then passed to a server and we get a I<response>
object in return that we can examine. The same simple model is used
for any kind of service we want to access.

If we want to fetch a document from a remote file server we send it
a request that contains a name for that document and the response
contains the document itself. If we want to send a mail message to
somebody then we send the request object which contains our message to
the mail server and the response object will contain an acknowledgment
that tells us that the message has been accepted and will be forwarded
to the receipients.

It is as simple as that!


=head2 Request object

The request object has the class name C<HTTP::Request> in
libwww-perl. The fact that the class name use C<HTTP::> as a name
prefix only implies that we use this model of communication. It does
not limit the kind of services we can try to send this I<request> to.
We send C<HTTP::Request>s both to ftp and gopher servers, as well as to
the local file system.

The main attributes of C<HTTP::Request> objects are:

=over 3

=item *

The B<method> is a short string that tells what kind of
request this is.  The most usual methods are B<GET>, B<PUT>,
B<POST> and B<HEAD>.

=item *

The B<url> is a string denoting the protocol, server and
the name of the "document" we want to access.  The url might
also encode various other parameters. This is the name of the
resource we want to access.

=item *

The B<headers> contain additional information about the
request and can also used to describe the content.  The headers
is a set of keyword/value pairs.

=item *

The B<content> is an arbitrary amount of binary data.

=back

=head2 Response object

The request object has the class name C<HTTP::Response> in
libwww-perl.  The main attributes of objects of this class are:

=over 3

=item *

The B<code> is a numerical value that encode the overall
outcome of the request.

=item *

The B<message> is a short (human readable) string that
corresponds to the I<code>.

=item *

The B<headers> contain additional information about the
response and they describe the content.

=item *

The B<content> is an arbitrary amount of binary data.

=back

Since we don't want to handle the <em>code</em> directly in our
programs the libwww-perl response object have methods that can be used
to query the kind of code present:

=over 3

=item *

is_success

=item *

is_redirect

=item *

is_error

=back

=head2 User Agent

Ok, I have created this nice I<request> object. What do I do
with it?

The answer is that you pass it on to the I<user agent> object
and it will take care of all the things that need to be done
(low-level communcation and error handling) and the user agent will
give you back a I<response> object. The user agent represents
your application on the network and it provides you with an interface
that can accept I<requests> and will return I<responses>.

There should be a nice figure here explaining this. It should
show the UA as an interface layer between the application code and the
network.

The libwww-perl class name for the user agent is
C<LWP::UserAgent>. Every libwww-perl application that wants to
communicate should create at least one object of this kind. The main
method provided by this object is request(). This method
takes an C<HTTP::Request> object as argument and will return a
C<HTTP::Response> object.

The C<LWP::UserAgent> has many other attributes that lets you
configure how it will interact with the network and with your
application code.

=over 3

=item *

The B<timeout> specify how much time we give remote servers
in creating responses before the library creates an internal
I<timeout> response.

=item *

The B<agent> specify the name that your application should
present itself as on the network.

=item *

The B<use_alarm> specify if it is ok for the user agent to
use the alarm(2) system to implement timeouts.

=item *

The B<use_eval> specify if the agent should raise an
expection (C<die> in perl) if an error condition occur.
       
=item *

The B<proxy> and B<no_proxy> specify when communication should go
through a proxy server. <URL:http://www.w3.org/pub/WWW/Proxies/>
       
=item *

The B<credentials> provide a way to set up usernames and
passwords that is needed to access certain services.

=back

Many applications would want even more control over how they
interact with the network and they get this by specializing the
C<LWP::UserAgent> by sub-classing.
 

=head1 OVERVIEW OF CLASSES AND PACKAGES

This table should give you a quick overview of the classes used by the
library. Indentation shows class inheritance.

 LWP::MemberMixin   -- Access to member variables of Perl5 classes
   LWP::UserAgent   -- WWW user agent class
     LWP::RobotUA   -- When developing a robot applications
   LWP::Protocol          -- Interface to various protocol schemes
     LWP::Protocol::http  -- http:// access
     LWP::Protocol::file  -- file:// access
     LWP::Protocol::ftp   -- ftp:// access
     ...

 LWP::Socket        -- Socket creation and IO

 HTTP::Headers      -- MIME/RFC822 style header (used by HTTP::Message)
 HTTP::Message      -- HTTP style message
   HTTP::Request    -- HTTP request
   HTTP::Response   -- HTTP response

 URI::URL           -- Uniform Resource Locators

 WWW::RobotRules    -- Parse robots.txt files

 HTML::Parse        -- Parse HTML documents
 HTML::Element      -- Building block for the parser
 HTML::Formatter    -- Convert HTML to readable formats

The following modules provide various functions and definitions.

 LWP                -- This file.  Library version number.
 LWP::MediaTypes    -- MIME types configuration (text/html etc.)
 LWP::Debug         -- Debug logging module
 LWP::Simple        -- Simplified procedural interface for common functions
 HTTP::Status       -- HTTP status code (200 OK etc)
 HTTP::Date         -- Date parsing module for HTTP date formats
 HTTP::Negotiate    -- HTTP content negotiation calculation
 File::Listing      -- Parse directory listings

HTTP use the Base64 encoding at some places.  The QuotedPrint module
is just included to make the MIME:: collection more complete.

 MIME::Base64       -- Base64 encoding/decoding routines
 MIME::QuotedPrint  -- Quoted Printanle encoding/decoding routines

The following modules does not have much to do with WWW, but are
included just because I am lazy and did not want to make separate
distributions for them.

 Font::AFM          -- Parse Adobe Font Metric files
 File::CounterFile  -- Persistent counter class


=head1 MORE DOCUMENTATION

You should first read the documentation for LWP::UserAgent.  The
L<lwpcook> contains the libwww-perl cookbook that contain examples of
typical usage of the library.  Take a look at how the scripts
C<lwp-request> and C<lwp-mirror> are implemented.  Even more examples
are found among the tests in the F<t> directory.

=head1 BUGS

The library can not handle multiple simultaneous requests.
Check what's left in the TODO file.

=head1 ACKNOWLEDGEMENTS

This package ows a lot in motivation, design, and code, to the
libwww-perl library for Perl 4, maintained by Roy Fielding
<fielding@ics.uci.edu>.

That package used work from Alberto Accomazzi, James Casey, Brooks
Cutter, Martijn Koster, Oscar Nierstrasz, Mel Melchner, Gertjan van
Oosten, Jared Rhine, Jack Shirazi, Gene Spafford, Marc VanHeyningen,
Steven E. Brenner, Marion Hakanson, Waldemar Kebsch, Tony Sanders, and
Larry Wall; see the libwww-perl-0.40 library for details.

The primary architect for this Perl 5 library is Martijn Koster and
Gisle Aas, with lots of help from Graham Barr, Tim Bunce, Andreas
Koenig, Jared Rhine, and Jack Shirazi.


=head1 COPYRIGHT

  Copyright 1995, Martijn Koster
  Copyright 1995-1996, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likly to be available from:

 http://www.sn.no/libwww-perl/

The best place to discuss this code is on the
<libwww-perl@ics.uci.edu> mailing list.

=cut
