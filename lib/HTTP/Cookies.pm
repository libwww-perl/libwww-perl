package HTTP::Cookies;

# Based on draft-ietf-http-state-man-mec-03.txt and
# http://www.netscape.com/newsref/std/cookie_spec.html

use strict;
use HTTP::Date qw(str2time time2str);
require LWP::Debug;

use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

=head1 NAME

HTTP::Cookies - Cookie storage and management

=head1 SYNOPSIS

 use HTTP::Cookies;
 $cookie_jar = HTTP::Cookies->new;

 $cookie_jar->add_cookie_header($request);
 $cookie_jar->extract_cookies($response);

=head1 DESCRIPTION

Cookies are a general mechanism which server side connections can use
to both store and retrieve information on the client side of the
connection.  For more information about cookies referer to
<URL:http://www.netscape.com/newsref/std/cookie_spec.html> and
<URL:http://www.cookiecentral.com/>.

Instances of the class I<HTTP::Cookies> are able to store a collection
of Set-Cookie2?:-headers and is able to use this information to
initialize Cookie-headers in I<HTTP::Request> objects.  The state of
the I<HTTP::Cookies> can be saved and restored from files.

=head1 METHODS

The following methods are provided:

=over 4

=cut

# A HTTP::Cookies object is a hash.  The main attribute is the
# COOKIES 3 level hash:  $self->{COOKIES}{$domain}{$path}{$key}.


=item $cookie_jar = HTTP::Cookies->new;

The constructor.  Takes hash style parameters.

=cut

sub new
{
    my $class = shift;
    my $self = bless {
	COOKIES => {},
    }, $class;
    my %cnf = @_;
    for (keys %cnf) {
	$self->{lc($_)} = $cnf{$_};
    }
    $self->load;
    $self;
}


=item $cookie_jar->add_cookie_header($request);

The add_cookies() method will set the appropriate Cookie:-header for
the I<HTTP::Request> object given as argument.  The $request must have
a valid url() attribute before this method is called.

=cut

sub add_cookie_header
{
    my $self = shift;
    my $request = shift || return;
    my $url = $request->url;
    my $domain = $url->host;
    my $secure_request = ($url->scheme eq "https");
    my $request_path = $url->path;   # XXX: epath
    my $request_port = $url->port;
    my $now = time();

    my @cval;    # cookie values for the "Cookie" header
    my $set_ver;

    while (($domain =~ tr/././) >= 2) {   # must be at least 2 dots

        LWP::Debug::debug("Checking $domain for cookies");
	my $cookies = $self->{COOKIES}{$domain};
	next unless $cookies;

	# Want to add cookies corresponding to the most specific paths
	# first (i.e. longest path first)
	my $path;
	for $path (sort {length($b) <=> length($a) } keys %$cookies) {
            LWP::Debug::debug("- checking cookie path=$path");
	    # XXX: URL encoding of path (the specification is unclear)
	    if (index($request_path, $path) != 0) {
	        LWP::Debug::debug("  path $path:$request_path does not fit");
		next;
	    }

	    my($key,$array);
	    while (($key,$array) = each %{$cookies->{$path}}) {
		my($version,$val,$port,$path_spec,$secure,$expires) = @$array;
	        LWP::Debug::debug(" - checking cookie $key=$val");
		if ($secure && !$secure_request) {
		    LWP::Debug::debug("   not a secure requests");
		    next;
		}
		if ($expires && $expires < $now) {
		    LWP::Debug::debug("   expired");
		    next;
		}
		if ($port) {
		    #XXX: must also handle empty port ""
		    my $found;
		    my $p;
		    for $p (split(/,/, $port)) {
			$found++, last if $p eq $request_port;
		    }
		    unless ($found) {
		        LWP::Debug::debug("   port $port:$request_port does not fit");
			next;
		    }
		}
	        LWP::Debug::debug("   it's a match");

		# set version number of cookie header.
	        # XXX: What should it be if multiple matching
                #      Set-Cookie headers have different versions themselves
		if (!$set_ver++) {
		    if ($version >= 1) {
			push(@cval, "\$Version=$version");
		    } else {
			$request->header(Cookie2 => "\$Version=1");
		    }
		}

		# do we need to quote the value
		if ($val =~ /\W/) { 
		    $val =~ s/([\\\"])/\\$1/g;
		    $val = qq("$val");
		}

		# and finally remember this cookie
		push(@cval, "$key=$val");
		if ($version >= 1) {
		    push(@cval, qq(\$Path="$path"))     if $path_spec;
		    push(@cval, qq(\$Domain="$domain")) if $domain =~ /^\./;
		    if (defined $port) {
			my $p = '$Port';
			$p .= qq(="$port") if length $port;
			push(@cval, $p);
		    }
		}

	    }
        }

    } continue {
	# Try with a more general domain:  www.sol.no ==> .sol.no
	$domain =~ s/^\.?[^.]*//;
    }

    $request->header(Cookie => join("; ", @cval)) if @cval;

    $request;
}


=item $cookie_jar->extract_cookies($response);

The extract_cookies() method will look for Set-Cookie:-headers in the
I<HTTP::Response> object passed as argument.  If some of these headers
are found they are used to update the state of the $cookie_jar.

=cut

sub extract_cookies
{
    my $self = shift;
    my $response = shift || return;
    my @set = $response->split_header_words("Set-Cookie2");
    my $netscape_cookies;
    unless (@set) {
	@set = $response->_header("Set-Cookie");
	return $response unless @set;
	$netscape_cookies++;
    }

    my $url = $response->request->url;
    my $req_host = $url->host;
    my $req_port = $url->port;
    my $req_path = $url->path;
    
    if ($netscape_cookies) {
	# The old Netscape cookie format for Set-Cookie
        # http://www.netscape.com/newsref/std/cookie_spec.html
	# can for instance contain an unquoted "," in the expires
	# field, so we have to use this ad-hoc parser.
	my $now = time();
	my @old = @set;
	@set = ();
	my $set;
	for $set (@old) {
	    my @cur;
	    my $param;
	    my $expires;
	    for $param (split(/\s*;\s*/, $set)) {
		my($k,$v) = split(/\s*=\s*/, $param, 2);
		#print "$k => $v\n";
		my $lc = lc($k);
		if ($lc eq "expires") {
		    push(@cur, "Max-Age" => str2time($v) - $now);
		    $expires++;
		} else {
		    push(@cur, $k => $v);
		}
	    }
	    push(@cur, "Port" => $req_port);
	    push(@cur, "Discard" => undef) unless $expires;
	    push(@cur, "Version" => 0);
	    push(@set, \@cur);
	}
    }

  SET_COOKIE:
    for my $set (@set) {
	next unless @$set >= 2;

	my $key = shift @$set;
	my $val = shift @$set;

        LWP::Debug::debug("Set cookie $key => $val");

	my %hash;
	while (@$set) {
	    my $k = shift @$set;
	    my $v = shift @$set;
	    $v = 1 unless defined $v;
	    my $lc = lc($k);
	    # don't loose case distinction for unknown fields
	    $k = $lc if $lc =~ /^(?:discard|domain|max-age|
                                    path|port|secure|version)$/x;
	    next if exists $hash{$k};  # only first value is signigicant
	    $hash{$k} = $v;
	};

	my %orig_hash = %hash;
	my $version   = delete $hash{version};
	my $discard   = delete $hash{discard};
	my $secure    = delete $hash{secure};
	my $maxage    = delete $hash{'max-age'};

	# Check domain
	my $domain  = delete $hash{domain};
	if (defined $domain) {
	    unless ($domain =~ /\./) {
	        LWP::Debug::debug("Domain $domain contains no dot");
		next SET_COOKIE;
	    }
	    $domain = ".$domain" unless $domain =~ /^\./;
	    if ($domain =~ /\.\d+$/) {
	        LWP::Debug::debug("IP-address $domain illeagal as domain");
		next SET_COOKIE;
	    }
	    my $len = length($domain);
	    unless (substr($req_host, -$len) eq $domain) {
	        LWP::Debug::debug("Domain $domain does not match host $req_host");
		next SET_COOKIE;
	    }
	    my $hostpre = substr($req_host, 0, length($req_host) - $len);
	    if ($hostpre =~ /\./) {
	        LWP::Debug::debug("Host prefix contain a dot: $hostpre => $domain");
		next SET_COOKIE;
	    }
	} else {
	    $domain = $req_host;
	}

	my $path = delete $hash{path};
	my $path_spec;
	if (defined $path) {
	    $path_spec++;
	    if (!$netscape_cookies &&
                substr($req_path, 0, length($path)) ne $path) {
	        LWP::Debug::debug("Path $path is not a prefix of $req_path");
		next SET_COOKIE;
	    }
	} else {
	    $path = $req_path;
	    $path =~ s,/[^/]*$,,;
	    $path = "/" unless length($path);
	}

	my $port;
	if (exists $hash{port}) {
	    $port = delete $hash{port};
	    $port = "" unless defined $port;
	    $port =~ s/\s+//g;
	    if (length $port) {
		my $found;
		for my $p (split(/,/, $port)) {
		    unless ($p =~ /^\d+$/) {
		      LWP::Debug::debug("Bad port $port (not numeric)");
			next SET_COOKIE;
		    }
		    $found++ if $p eq $req_port;
		}
		unless ($found) {
		    LWP::Debug::debug("Request port ($req_port) not found in $port");
		    next SET_COOKIE;
		}
	    }
	}
	$self->set_cookie($version,$key,$val,$path,$domain,$port,$path_spec,$secure,$maxage,$discard, \%hash)
	    if $self->set_cookie_ok(\%orig_hash);
    }

    $response;
}

sub set_cookie_ok { 1 };

=item $cookie_jar->set_cookie($version, $key, $val, $path, $domain, $port, $path_spec, $secure, $maxage, $discard, \%rest)

The set_cookie() method updates the state of the $cookie_jar.  The
$key, $val, $domain, $port and $path arguments are strings.  The
$path_spec, $secure, $discard arguments are boolean values. The $maxage
value is a number indicating number of seconds that this cookie will
live.  A value <= 0 will delete this cookie.  The %rest are a place
for various other attributes like "Comment" and "CommentURL".

=cut

sub set_cookie
{
    my $self = shift;
    my($version,
       $key, $val, $path, $domain, $port,
       $path_spec, $secure, $maxage, $discard, $rest) = @_;

    # there must always be at least 2 dots in a domain
    return $self if ($domain =~ tr/././) < 2;

    # path and key can not be empty (key can't start with '$')
    return $self if !defined($path) || $path !~ m,^/, ||
	            !defined($key)  || $key  !~ m,[^\$],;

    # ensure legal port
    if (defined $port) {
	return $self unless $port eq "" || $port =~ /^\d+(?:,\d+)*$/;
    }

    my $expires;
    if (defined $maxage) {
	if ($maxage <= 0) {
	    delete $self->{COOKIES}{$domain}{$path}{$key};
	    return $self;
	}
	$expires = time() + $maxage;
    }
    $version = 0 unless defined $version;

    my @array = ($version, $val,$port,
		 $path_spec,
		 $secure, $expires, $discard);
    push(@array, {%$rest}) if defined($rest) && %$rest;
    # trim off undefined values at end
    pop(@array) while !defined $array[-1];

    $self->{COOKIES}{$domain}{$path}{$key} = \@array;
    $self;
}

=item $cookie_jar->save;

=cut

sub save
{
    0;   # XXX: should save in "Set-Cookie3" format
}

=item $cookie_jar->load;

=cut

sub load
{
    0;
}

=item $cookie_jar->revert;

=cut

sub revert
{
    my $self = shift;
    $self->clear->load;
    $self;
}

=item $cookie_jar->clear;

Invoking this method will empty the $cookie_jar.

=cut

sub clear
{
    my $self = shift;
    if (@_ == 0) {
	$self->{COOKIES} = {};
    } elsif (@_ == 1) {
	delete $self->{COOKIES}{$_[0]};
    } elsif (@_ == 2) {
	delete $self->{COOKIES}{$_[0]}{$_[1]};
    } elsif (@_ == 3) {
	delete $self->{COOKIES}{$_[0]}{$_[1]}{$_[2]};
    } else {
	require Carp;
        Carp::carp('Usage: $c->clear([domain [,path [,key]]])');
    }
    $self;
}

sub DESTROY
{
    my $self = shift;
    LWP::Debug::trace("($self)");
    $self->save unless $self->{'dont_save'};
}

sub scan
{
    my($self, $cb) = @_;
    my($domain,$path,$key);
    for $domain (sort keys %{$self->{COOKIES}}) {
	for $path (sort keys %{$self->{COOKIES}{$domain}}) {
	    for $key (sort keys %{$self->{COOKIES}{$domain}{$path}}) {
		my($version,$val,$port,$path_spec,
		   $secure,$expires,$discard,$rest) =
		       @{$self->{COOKIES}{$domain}{$path}{$key}};
		$rest = {} unless defined($rest);
		&$cb($version,$key,$val,$path,$domain,$port,
		     $path_spec,$secure,$expires,$discard,$rest);
	    }
	}
    }
}

=item $cookie_jar->as_string;

The as_string() method will return the state of the $cookie_jar
represented as a sequence of "Set-Cookie3" header lines separated by
"\n".

=cut

sub as_string
{
    my $self = shift;
    my @res;
    $self->scan(sub {
	my($version,$key,$val,$path,$domain,$port,
	   $path_spec,$secure,$expires,$discard,$rest) = @_;
	my $line = "Set-Cookie3: $key=$val";
	$line .= "; " . ($path_spec?"path":"path*") . "=$path";
	$line .= "; domain=$domain";
	$line .= "; port=\"$port\"" if defined($port);
	$line .= "; secure" if $secure;
	$line .= '; expires="' . HTTP::Date::time2isoz($expires) . '"'
	    if $expires;
	$line .= '; discard' if $discard;
	my($k);
	for $k (sort keys %$rest) {
	    $line .= "; $k=\"$rest->{$k}\"";
	}
	$line .= "; version=$version";
	push(@res, $line);
    });
    join("\n", @res, "");
}


=back

=head1 SUB CLASSES

We also provide a subclass called I<HTTP::Cookies::Netscape> which make
cookie loading and saving compatible with Netscape cookie files.  You
should be able to have LWP share Netscape's cookies by constructing
your $cookie_jar like this:

 $cookie_jar = HTTP::Cookies::Netscape->new(
                   Path => "$ENV{HOME}/.netscape/cookies"
               );

=cut

package HTTP::Cookies::Netscape;

use vars qw(@ISA);
@ISA=qw(HTTP::Cookies);

sub load
{
    my($self, $file) = @_;
    $file ||= $self->{'path'} || return;
    local(*FILE, $_);
    my @cookies;
    open(FILE, $file) || return;
    my $magic = <FILE>;
    unless ($magic =~ /^\# Netscape HTTP Cookie File/) {
	warn "$file does not look like a netscape cookies file" if $^W;
	close(FILE);
	return;
    }
    my $now = time();
    while (<FILE>) {
	next if /^\s*\#/;
	next if /^\s*$/;
	chomp;
	my($domain,$bool1,$path,$secure, $expires,$key,$val) = split(/\t/, $_);
	$secure = ($secure eq "TRUE");
	$self->set_cookie(undef,$key,$val,$path,$domain,undef,
			  0,$secure,$expires-$now, 0);
    }
    close(FILE);
    1;
}

sub save
{
    my($self, $file) = @_;
    print <<EOT;
# Netscape HTTP Cookie File
# http://www.netscape.com/newsref/std/cookie_spec.html
# This is a generated file!  Do not edit.

EOT

    my $now = time;
    $self->scan(sub {
	my($version,$key,$val,$path,$domain,$port,
	   $path_spec,$secure,$expires,$discard,$rest) = @_;
	return if $discard;
	return if $now > $expires;
	$secure = $secure ? "TRUE" : "FALSE";
	my $bool = $domain =~ /^\./ ? "TRUE" : "FALSE";
	print join("\t", $domain, $bool, $path, $secure, $expires, $key, $val), "\n";
    });

}

package HTTP::Headers;   # XXX: this function should move

sub split_header_words
{
    my($self, $field) = @_;
    my @val = $self->_header($field);
    return unless @val;
    my @res;
    for (@val) {
	my @cur;
	while (length) {
	    if (s/^\s*(=*[^\s=;,]+)//) {
		push(@cur, $1);
		if (s/^\s*=\s*\"([^\"\\]*(?:\\.[^\"\\]*)*)\"//) {
		    my $val = $1;
		    $val =~ s/\\(.)/$1/g;
		    push(@cur, $val);
		} elsif (s/^\s*=\s*([^;,]+)//) {
		    my $val = $1;
		    $val =~ s/\s+$//;
		    push(@cur, $val);
		} else {
		    push(@cur, undef);
		}
	    } elsif (s/^\s*,//) {
		push(@res, [@cur]);
		@cur = ();
	    } elsif (s/^\s*;?//) {
		# continue
	    } else {
		warn "This should not happen: $_\n";
	    }
	}
	push(@res, \@cur) if @cur;
    }
    @res;
}

1;

__END__

=head1 COPYRIGHT

Copyright 1997, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


