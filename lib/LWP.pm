#
# $Id: LWP.pm,v 1.12 1995/08/09 08:55:53 aas Exp $

package LWP;

$VERSION = "0.02";

sub Version { $VERSION; }

require 5.001;
require LWP::UserAgent;  # this should load everything you need

1;

__END__

=head1 NAME

LWP - Library for WWW access in Perl

=head1 ARCHITECTURE

The architecture of the library is heavily object oriented.  The user
agent, requests sent and responses received from the WWW server are
all represented by objects.  This makes a simple but yet powerful
interface to these services.  The interface is easy to extend and
customize for your needs.

You should first read the documentation for LWP::UserAgent.  Then you
might want to look at how the scripts C<request> and C<mirror> are
implemented.  More examples are found among the tests in the F<t>
directory.

=head2 Overview of classes and packages

This table should give you a quick overview of the classes used by the
library. Indentation shows class inheritance.

 LWP::MemberMixin   -- Access to member variables of Perl5 classes
   LWP::UserAgent   -- WWW user agent class

   LWP::Message     -- HTTP style message
     LWP::Request   -- HTTP request
     LWP::Response  -- HTTP response

   LWP::Protocol          -- Interface to various protocol schemes
     LWP::Protocol::http  -- http:// access
     LWP::Protocol::file  -- file:// access

 LWP::MIMEheader    -- MIME/RFC822 style header (used by LWP::Message)
 LWP::Socket        -- Socket creation and reading (LWP::Protocol::http)
 URI::URL           -- Uniform Resource Locators (separate library)

The following modules provide various functions and definitions.

 LWP                -- This file.  Library version number.
 LWP::MIMEtypes     -- MIME types configuration (text/html etc.)
 LWP::StatusCode    -- HTTP status code (200 OK etc)
 LWP::Date          -- Date parsing module
 LWP::Debug         -- Debug logging module
 LWP::Simple        -- Simplified procedural interface for common functions

=head1 ACKNOWLEDGEMENTS

This package ows a lot in motivation, design, and code, to the
libwww-perl library for Perl 4, maintained by Roy Fielding
<fielding@ics.uci.edu>.

That package used work from Alberto Accomazzi, James Casey, Brooks
Cutter, Martijn Koster, Oscar Nierstrasz, Mel Melchner, Gertjan van
Oosten, Jared Rhine, Jack Shirazi, Gene Spafford, Marc VanHeyningen,
Steven E. Brenner, Marion Hakanson, Waldemar Kebsch, Tony Sanders, and
Larry Wall; see the libwww-perl library for details.

The primary architect for this Perl 5 library is Martijn Koster and
Gisle Aas, with lots of help from Graham Barr, Tim Bunce, Andreas
Koenig, Jared Rhine, and Jack Shirazi.


=head1 COPYRIGHT

Copyright (c) 1995 Martijn Koster. All rights reserved.
Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likly to be available from:

 http://www.oslonett.no/home/aas/perl/www/

The best place to discuss this code is on the
<libwww-perl@ics.uci.edu> mailing list.  The email addresses of the
principal authors are <m.koster@nexor.co.uk> and <aas@oslonett.no>.

=cut
