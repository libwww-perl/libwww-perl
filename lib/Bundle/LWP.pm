package Bundle::LWP;

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

1;

__END__

=head1 NAME

Bundle::LWP - A bundle to install all libwww-perl related modules

=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::LWP'

=head1 CONTENTS

Net::FTP 2.00      - If you want ftp://-support

MIME::Base64       - Used in authentication headers

MD5                - Needed to Digest authentication

=head1 DESCRIPTION

This bundle defines all reqreq modules for libwww-perl.


=head1 AUTHOR

Gisle Aas E<lt>aas@sn.no>

=cut
