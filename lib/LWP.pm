#
# $Id: LWP.pm,v 1.4 1995/07/11 13:22:46 aas Exp $

package LWP;

$VERSION = "0.01";  # Automatically updated by 'make-dist'

require 5.001;
require LWP::UserAgent;

1;

__END__

=head1 NAME

LWP - Library for the Web in Perl 5

=head INTRO

The latest version of this library will be available from:

 http://www.oslonett.no/home/aas/perl/www/

This code should be discussed on the libwww-perl@ics.UCI.EDU
mailing list.

=head1 ARCHITECTURE

This architecture is very heavily object oriented.

=head2 Overview of classes and packages

 LWP::UserAgent   -- WWW user agent class

 LWP::Message     -- HTTP style message
   LWP::Request   -- HTTP request
   LWP::Response  -- HTTP response

 LWP::Protocol
  LWP::Protocol::http  -- http:// access
  LWP::Protocol::file  -- file:// access

 LWP::MIMEheader  -- MIME/RFC822 style header
 LWP::MIMEtypes   -- MIME types configuration (text/html etc.)
 LWP::StatusCode  -- HTTP status code (200 OK etc)

 LWP::Date        -- Date parsing package
 LWP::Debug       -- Debug logging package
 LWP::MemberMixin -- Access to member variables of Perl5 classes
 LWP::Socket      -- Socket creation and reading

 LWP::Simple      -- Simplified interface for common functions

=head1 ACKNOWLEDGEMENTS

This package ows a lot in motivation, design, and code, to the
libwww-perl library for Perl 4, maintained by Roy Fielding
<fielding@ics.uci.edu>.

That package used work from Alberto Accomazzi, James Casey, Brooks
Cutter, Martijn Koster, Oscar Nierstrasz, Mel Melchner, Gertjan van
Oosten, Jared Rhine, Jack Shirazi, Gene Spafford, Marc VanHeyningen,
Steven E. Brenner, Marion Hakanson, Waldemar Kebsch, Tony Sanders, and
Larry Wall; see the libwww-perl library for details.

The primary architect for this Perl 5 library is Martijn Koster, with
lots of help from Gisle Aas, Graham Barr, Tim Bunce, Andreas Koenig,
Jared Rhine, and Jack Shirazi.

=head1 TO DO

More documentation

Lots of other things.

=head1 COPYRIGHT

Copyright (c) 1995 Martijn Koster. All rights reserved.
Copyright (c) 1995 Gisle Aas. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
