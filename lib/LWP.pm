#
# $Id: LWP.pm,v 1.1 1995/06/11 23:29:43 aas Exp $

=head1 NAME

LWP -- Library for the Web in Perl 5

=head INTRO

Currently the latest version is available from:

 http://web.nexor.co.uk/users/mak/doc/libwww-perl5/lwp.tar.gz
 http://web.nexor.co.uk/users/mak/doc/libwww-perl5/lwp.tar
 http://web.nexor.co.uk/users/mak/doc/libwww-perl5/lwp/


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

=head2 XXX

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

Receive comments on this code.

MDA! I can really do with an authenticated file upload facility,
and now MD5.pm is here...

More documentation

Lots of other things.

=head1 COPYRIGHT

Copyright (c) 1995 Martijn Koster. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

require LWP::UserAgent;
require LWP::http;
require LWP::file;

1;

