package URI::Heuristic;

# $Id: Heuristic.pm,v 4.1 1997/10/13 13:04:36 aas Exp $

=head1 NAME

friendly_url - Expand URL using heuristics

=head1 SYNOPSIS

 use URI::Heuristic qw(friendly_url);
 $url = friendly_url("perl");             # http://www.perl.com
 $url = friendly_url("www.sol.no/sol");   # http://www.sol.no/no
 $url = friendly_url("aas");              # http://www.aas.no
 $url = friendly_url("ftp.funet.fi");     # ftp://ftp.funet.fi
 $url = friendly_url("/etc/passwd");      # file:/etc/passwd

=head1 DESCRIPTION

This module provide functions that expand strings into real URLs using
some heuristics.  The following functions are provided:

=over 4

=item friendly_url($str)

The friendly_url() function will try to make the string passed as
argument into a proper absolute URL string.

=item url($str)

This functions work the same way as friendly_url() but it will
return a C<URI::URL> object.

=back


=head1 COPYRIGHT

Copyright 1997, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;

use vars qw(@EXPORT_OK);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(url friendly_url);

my $my_country;
eval {
    require Net::Domain;
    my $fqdn = Net::Domain::hostfqdn();
    $my_country = lc($1) if $fqdn =~ /\.([a-zA-Z]{2})$/;
};


sub url ($)
{
    require URI::URL;
    URI::URL->new(friendly_url($_[0]));
}


sub friendly_url ($)
{
    local($_) = @_;
    return unless defined;

    s/^\s+//;
    s/\s+$//;

    if (/^(www|web|http)\./) {
	$_ = "http://$_";

    } elsif (/^(ftp|gopher|news|wais)\./) {
	$_ = "$1://$_";

    } elsif (m,^/,      ||          # absolute file name
	     m,^\.\.?/, ||          # relative file name
	     m,^[a-zA-Z]:[/\\],)    # dosish file name
    {
	$_ = "file:$_";

    } elsif (!/^[.+\-\w]+:/) {      # no scheme specified
	if (s/^([\w\.]+)//) {
	    my $host = $1;

	    if ($host !~ /\./) {
		my @guess;
		push(@guess, "www.$host.$my_country") if $my_country;
		push(@guess, map { "www.$host.$_" } "com", "org");
		push(@guess, map { "www.$host.$_"} "gov", "mil")
		    if $my_country && $my_country eq "us";

		my $guess;
		for $guess (@guess) {
		    if (gethostbyname($guess)) {
			$host = $guess;
			last;
		    }
		}
	    }
	    $_ = "http://$host$_";
	}
	
    }
    $_;
}

1;
