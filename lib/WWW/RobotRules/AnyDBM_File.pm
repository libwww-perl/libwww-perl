# $Id: AnyDBM_File.pm,v 1.2 1996/09/17 11:42:06 aas Exp $

package WWW::RobotRules::AnyDBM_File;

require  WWW::RobotRules;
@ISA = qw(WWW::RobotRules);

use Carp ();
use AnyDBM_File;
use Fcntl;
use strict;

=head1 NAME

WWW::RobotRules::AnyDBM_File - Persistent Robot Rules

=head1 SYNOPSIS

 require WWW::RobotRules::AnyDBM_File;
 require LWP::RobotUA;

 # Create a robot useragent that uses a diskcaching RobotRules
 my $rules = new WWW::RobotRules::AnyDBM_File 'my-robot/1.0', 'cachefile';
 my $ua = new WWW::RobotUA 'my-robot/1.0', 'me@foo.com', $rules;

 # Then just use $ua as usual
 $res = $ua->request($req);

=head1 DESCRIPTION

This is a subclass of L<WWW::RobotRules> that uses the AnyDBM_File
package to implement diskcaching of robots.txt.  The constructor takes
an extra argument specifying the name of the DBM file to use.

=head1 SE ALSO

L<WWW::RobotRules>

=cut

sub new 
{ 
  my ($class, $ua, $file) = @_;
  Carp::croak('WWW::RobotRules::AnyDBM_File cachfile required') unless $file;

  my $self = bless { }, $class;
  $self->{'filename'} = $file;
  tie %{$self->{'dbm'}}, 'AnyDBM_File', $file, O_CREAT|O_RDWR, 0640;
  $self->agent($ua);

  $self;
}

sub agent {
    my($self, $newname) = @_;
    my $old = $self->{'dbm'}{"|ua-name|"};
    if (defined $newname) {
	$newname =~ s!/?\s*\d+.\d+\s*$!!;  # loose version
	unless ($old && $old eq $newname) {
	# Old info is now stale.
	    my $file = $self->{'filename'};
	    tie %{$self->{'dbm'}}, 'AnyDBM_File', $file, O_TRUNC|O_RDWR, 0640;
	    $self->{'dbm'}{"|ua-name|"} = $newname;
	}
    }
}

sub no_vists {
    my ($self, $netloc) = @_;
    (split(/;\s*/, $self->{'dbm'}{"$netloc|vis"}))[0];
}

sub last_visit {
    my ($self, $netloc) = @_;
    (split(/;\s*/, $self->{'dbm'}{"$netloc|vis"}))[1];
}

sub fresh_until {
    my ($self, $netloc, $fresh) = @_;
    my $old = $self->{'dbm'}{"$netloc|exp"};
    if ($old) {
	$old =~ s/;.*//;  # remove cleartext
    }
    if (defined $fresh) {
	$fresh .= "; " . localtime($fresh);
	$self->{'dbm'}{"$netloc|exp"} = $fresh;
    }
    $old;
}

sub visit {
    my($self, $netloc, $time) = @_;
    $time ||= time;

    my $count = 0;
    my $old = $self->{'dbm'}{"$netloc|vis"};
    if ($old) {
	my $last;
	($count,$last) = split(/;\s*/, $old);
	$time = $last if $last > $time;
    }
    $count++;
    $self->{'dbm'}{"$netloc|vis"} = "$count; $time; " . localtime($time);
}

sub push_rules {
    my($self, $netloc, @rules) = @_;
    my $cnt = 1;
    $cnt++ while $self->{'dbm'}{"$netloc|r$cnt"};

    foreach (@rules) {
	$self->{'dbm'}{"$netloc|r$cnt"} = $_;
	$cnt++;
    }
}

sub clear_rules {
    my($self, $netloc) = @_;
    my $cnt = 1;
    while ($self->{'dbm'}{"$netloc|r$cnt"}) {
	delete $self->{'dbm'}{"$netloc|r$cnt"};
	$cnt++;
    }
}

sub rules {
    my($self, $netloc) = @_;
    my @rules = ();
    my $cnt = 1;
    while (1) {
	my $rule = $self->{'dbm'}{"$netloc|r$cnt"};
	last unless $rule;
	push(@rules, $rule);
	$cnt++;
    }
    @rules;
}

sub dump
{
}

1;

=head1 AUTHORS

Hakan Ardo E<lt>hakan@munin.ub2.lu.se>, Gisle Aas E<lt>aas@sn.no>

=cut

