# $Id: RobotRules.pm,v 1.6 1996/04/09 15:44:56 aas Exp $

package WWW::RobotRules;

=head1 NAME

WWW::RobotsRules - Parse robots.txt files

=head1 SYNOPSIS

 require WWW::RobotRules;
 my $robotsrules = new WWW::RobotRules 'MOMspider/1.0';

 use LWP::Simple qw(get);

 $url = "http://some.place/robots.txt";
 my $robots_txt = get $url;
 $robotsrules->parse($url, $robots_txt);

 $url = "http://some.other.place/robots.txt";
 my $robots_txt = get $url;
 $robotsrules->parse($url, $robots_txt);

 # Now we are able to check if a URL is valid for those servers that
 # we have obtained and parsed "robots.txt" files for.
 if($robotsrules->allowed($url)) {
     $c = get $url;
     ...
 }

=head1 DESCRIPTION

This module parses a F</robots.txt> file as specified in
"A Standard for Robot Exclusion", described in
<URL:http://info.webcrawler.com/mak/projects/robots/norobots.html>
Webmasters can use the F</robots.txt> file to disallow conforming
robots access to parts of their WWW server.

The parsed file is kept in the WWW::RobotRules object, and this object
provide methods to check if access to a given URL is prohibited.  The
same WWW::RobotRules object can parse multiple F</robots.txt> files.

=head1 METHODS

=cut

$VERSION = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);
sub Version { $VERSION; }


use URI::URL ();
use strict;


=head2 $rules = new WWW::RobotRules 'MOMspider/1.0'

This is the constructor for WWW::RobotRules objects.  The argument
given to new() is the name of the robot.

=cut

sub new {
    my($class, $ua) = @_;

    $ua =~ s!/?\s*\d+.\d+\s*$!! if (defined $ua);	# lose version

    bless {
	'ua' => $ua,
	'rules' => undef,
    }, $class;
}

=head2 $rules->parse($url, $content)

The parse() method takes as arguments the URL that was used to
retrieve the F</robots.txt> file, and the contents of the file.

=cut

sub parse {
    my($self, $url, $txt) = @_;

    $url = new URI::URL $url unless ref($url);	# make it URL

    my $hostport = $url->host . ':' . $url->port;

    delete $self->{'rules'}{$hostport} if
	exists $self->{'rules'}{$hostport};

    $txt =~ s/\015\012/\n/mg;	# fix weird line endings

    my $ua;
    my $is_me = 0;		# 1 iff this record is for me
    my $isAnon = 0;		# 1 iff this record is for *
    my @meDisallowed = ();	# rules disallowed for me
    my @anonDisallowed = ();	# rules disallowed for *

    for(split(/\n/, $txt)) {
	s/\s*\#.*//;

	if (/^\s*$/) {		# blank line
	    if ($is_me) {
		# That was our record. No need to read the rest.
		last;
	    }
	    $is_me = $isAnon = 0;
	    @meDisallowed = ();
	}
	elsif (/^User-agent:\s*(.*)\s*$/i) {
	    $ua = $1;
	    if ($is_me) {
		# This record already had a User-agent that
		# we matched, so just continue.
	    }
	    elsif($self->is_me($ua)) {
		$is_me = 1;
	    }
	    elsif ($ua eq '*') {
		$isAnon = 1;
	    }
	}
	elsif (/^Disallow:\s*(.*)\s*$/i) {
	    unless (defined $ua) {
		warn "RobotRules: Disallow without preceding User-agent\n";
		$isAnon = 1;  # assume that User-agent: * was intended
	    }

	    my $full_path;
	    if ($1 eq '') {
		$full_path = '';
	    }
	    else {
		my $abs = new URI::URL $1, $url;
		$full_path = $abs->full_path();
	    }

	    if ($is_me) {
		push(@meDisallowed, $full_path);
	    }
	    elsif ($isAnon) {
		push(@anonDisallowed, $full_path);
	    }
	}
	else {
	    warn "RobotRules: Unexpected line: $_\n";
	}
    }

    if ($is_me) {
	$self->{'rules'}{$hostport} = \@meDisallowed;
    }
    elsif (@anonDisallowed) {
	$self->{'rules'}{$hostport} = \@anonDisallowed;
    }
}

# is_me()
#
# Returns TRUE if the given name matches the
# name of this robot
#
sub is_me {
    my($self, $ua) = @_;

    my $me = $self->{'ua'};
    return $ua =~ /$me/i;
}

=head2 $rules->allowed($url)

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
	return 0 if ($str =~ /^\Q$rule/);
    }
    return 1;
}

1;

__END__

=head1 ROBOTS.TXT

The format and semantics of the "/robots.txt" file are as follows
(this is an edited abstract of
<URL:http://info.webcrawler.com/mak/projects/robots/norobots.html>):

The file consists of one or more records separated by one or more
blank lines. Each record contains lines of the form

  <field-name>: <value>

The field name is case insensitive.  Text after the '#' character on a
line is ignored during parsing.  This is used for comments.  The
following <field-names> can be used:

=over 3

=item User-Agent

The value of this field is the name of the robot the record is
describing access policy for.  If more than one I<User-Agent> field is
present the record describes an identical access policy for more than
one robot. At least one field needs to be present per record.  If the
value is '*', the record describes the default access policy for any
robot that has not not matched any of the other records.

=item Disallow

The value of this field specifies a partial URL that is not to be
visited. This can be a full path, or a partial path; any URL that
starts with this value will not be retrieved

=back

=head2 Examples

The following example "/robots.txt" file specifies that no robots
should visit any URL starting with "/cyberworld/map/" or "/tmp/":

  # robots.txt for http://www.site.com/

  User-agent: *
  Disallow: /cyberworld/map/ # This is an infinite virtual URL space
  Disallow: /tmp/ # these will soon disappear

This example "/robots.txt" file specifies that no robots should visit
any URL starting with "/cyberworld/map/", except the robot called
"cybermapper":

  # robots.txt for http://www.site.com/

  User-agent: *
  Disallow: /cyberworld/map/ # This is an infinite virtual URL space

  # Cybermapper knows where to go.
  User-agent: cybermapper
  Disallow:

This example indicates that no robots should visit this site further:

  # go away
  User-agent: *
  Disallow: /

=head1 SEE ALSO

L<LWP::RobotUA>

=cut
