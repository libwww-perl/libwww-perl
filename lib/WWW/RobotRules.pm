#
# $Id: RobotRules.pm,v 1.3 1995/10/16 15:40:06 aas Exp $

=head1 NAME

WWW::RobotsRules - Parse robots.txt files

=head1 SYNOPSIS

 $robotsrules = new WWW::RobotRules 'MOMspider/1.0';

 $robotsrules->parse($url, $content);
    
 if($robotsrules->allowed($url)) {
     ...
 }

=head1 DESCRIPTION

This module parses a "/robots.txt" file as specified in
"A Standard for Robot Exclusion", described in
http://web.nexor.co.uk/users/mak/doc/robots/norobots.html.

Webmasters can use this file to disallow conforming robots access to
parts of their WWW server.

The parsed file is kept as a Perl object that support methods to
check if a given URL is prohibited.

Note that the same RobotRules object can parse multiple files.

=cut

package RobotRules;

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }

use URI::URL;
use strict;


=head2 new RobotRules 'MOMspider/1.0'

The argument given to C<new()> is the name of the robot.

=cut

sub new {
    my($class, $ua) = @_;

    $ua =~ s!/?\s*\d+.\d+\s*$!! if (defined $ua);	# lose version

    bless {
	'ua' => $ua,
	'rules' => undef,
    }, $class;
}

=head2 parse($url, $content)

Parse takes the URL that was used to retrieve the F</robots.txt>
file, and the contents of the file.

=cut

sub parse {
    my($self, $url, $txt) = @_;

    $url = new URI::URL $url  unless ref($url);	# make it URL

    my $hostport = $url->host . ':' . $url->port;

    delete $self->{'rules'}{$hostport} if
	exists $self->{'rules'}{$hostport};

    $txt =~ s/\015\012/\n/mg;	# fix weird line endings

    my $ua;
    my $isMe = 0;		# 1 iff this record is for me
    my $isAnon = 0;		# 1 iff this record is for *
    my @meDisallowed = ();	# rules disallowed for me
    my @anonDisallowed = ();	# rules disallowed for *

    for(split(/\n/, $txt)) {
	s/\s*\#.*//;

	if (/^\s*$/) {		# blank line
	    if ($isMe) {
		# That was our record. No need to read the rest.
		last;
	    }
	    $isMe = $isAnon = 0;
	    @meDisallowed = ();
	}
	elsif (/^User-agent:\s*(.*)\s*$/i) {
	    $ua = $1;
	    if ($isMe) {
		# This record already had a User-agent that
		# we matched, so just continue.
	    }
	    elsif($self->isMe($ua)) {
		$isMe = 1;
	    }
	    elsif ($ua eq '*') {
		$isAnon = 1;
	    }
	}
	elsif (/^Disallow:\s*(.*)\s*$/i) {
	    warn "Disallow without preceding User-agent" unless 
		defined $ua;

	    my $full_path;
	    if ($1 eq '') {
		$full_path = '';
	    }
	    else {
		my $abs = new URI::URL $1, $url;
		$full_path = $abs->full_path();
	    }

	    if ($isMe) {
		push(@meDisallowed, $full_path);
	    }
	    elsif ($isAnon) {
		push(@anonDisallowed, $full_path);
	    }
	}
	else {
	    warn "Unexpected line: $_\n";
	}
    }

    if ($isMe) {
	$self->{'rules'}{$hostport} = \@meDisallowed;
    }
    elsif (@anonDisallowed) {
	$self->{'rules'}{$hostport} = \@anonDisallowed;
    }
}

# isMe()
#
# Returns TRUE if the given name matches the
# name of this robot
#
sub isMe {
    my($self, $ua) = @_;

    my $me = $self->{'ua'};
    return $ua =~ /$me/i;
}

=head2 allowed($url)

Returns TRUE if this robot is allowed to retrieve this URL.

=cut

sub allowed {
    my($self, $url) = @_;

    $url = new URI::URL $url unless ref($url);	# make it URL

    my $hostport = $url->host . ':' . $url->port;

    return 1 unless exists $self->{'rules'}{$hostport};

    my $str = $url->full_path;

    my $rule;
    for $rule (@{ $self->{'rules'}{$hostport}}) {
	return 1 if ($rule eq '');
	return 0 if ($str =~ /^$rule/);
    }
    return 1;
}

1;
