package URI::Heuristic;

# $Id: Heuristic.pm,v 4.4 1997/10/14 08:35:39 aas Exp $

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

use vars qw(@EXPORT_OK %LOCAL_GUESSING $DEBUG);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(url friendly_url);

my $my_country;
eval {
    require Net::Domain;
    my $fqdn = Net::Domain::hostfqdn();
    $my_country = lc($1) if $fqdn =~ /\.([a-zA-Z]{2})$/;

    # Some other heuristics to guess country?  Perhaps looking
    # at some environment variable (LANG, LC_ALL, ???)
    $my_country = $ENV{COUNTRY} if exists $ENV{COUNTRY};
};

%LOCAL_GUESSING =
(
 'us' => [qw(www.ACME.gov www.ACME.mil)],
 'uk' => [qw(www.ACME.co.uk www.ACME.ac.uk)],
 'au' => [qw(www.ACME.com.au www.ACME.org.au www.ACME.edu.au)],
 'il' => [qw(www.ACME.co.il www.ACME.org.il www.ACME.net.il)],
);


sub url ($)            # h_url(), url2(), uf_url()
{
    require URI::URL;
    URI::URL->new(friendly_url($_[0]));
}


sub friendly_url ($)   # expand_url(), uf_urlstr()
{
    local($_) = @_;
    return unless defined;

    s/^\s+//;
    s/\s+$//;

    if (/^(www|web|home)\./) {
	$_ = "http://$_";

    } elsif (/^(ftp|gopher|news|wais|http|https)\./) {
	$_ = "$1://$_";

    } elsif (m,^/,      ||          # absolute file name
	     m,^\.\.?/, ||          # relative file name
	     m,^[a-zA-Z]:[/\\],)    # dosish file name
    {
	$_ = "file:$_";

    } elsif (!/^[.+\-\w]+:/) {      # no scheme specified
	if (s/^(\w+(?:\.\w+)*)([\/:\?\#]|$)/$2/) {
	    my $host = $1;

	    if ($host !~ /\./ && $host ne "localhost") {
		my @guess;

		if ($my_country) {
		    my $special = $LOCAL_GUESSING{$my_country};
		    if ($special) {
			my @special = @$special;
			push(@guess, map { s/\bACME\b/$host/; $_ } @special);
		    } else {
			push(@guess, "www.$host.$my_country");
		    }
		}

		push(@guess, map "www.$host.$_",
                                 "com", "org", "net", "edu", "int");

		my $guess;
		for $guess (@guess) {
		    print STDERR "Looking up '$guess'\n" if $DEBUG;
		    if (gethostbyname($guess)) {
			$host = $guess;
			last;
		    }
		}
	    }
	    $_ = "http://$host$_";

	} else {
	    # pure junk, just return it unchanged...

	}
    }
    $_;
}

1;
