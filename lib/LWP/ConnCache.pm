package LWP::ConnCache;

# $Id: ConnCache.pm,v 1.2 2001/04/20 17:58:21 gisle Exp $

use strict;
use vars qw($VERSION $DEBUG);

$VERSION = "0.01";

sub new {
    my($class, %cnf) = @_;
    my $total_capacity = delete $cnf{total_capacity} || 1;
    if (%cnf && $^W) {
	require Carp;
	Carp::carp("Unrecognised options: @{[sort keys %cnf]}")
    }
    my $self = bless { conns => [] }, $class;
    $self->total_capacity($total_capacity);
    $self;
}

sub deposit {
    my($self, $type, $key, $conn) = @_;
    push(@{$self->{conns}}, [$conn, $type, $key, time]);
    $self->enforce_limits($type);
    return;
}

sub withdraw {
    my($self, $type, $key) = @_;
    my $conns = $self->{conns};
    for my $i (0 .. @$conns - 1) {
	my $c = $conns->[$i];
	next unless $c->[1] eq $type && $c->[2] eq $key;
	splice(@$conns, $i, 1);  # remove it
	return $c->[0];
    }
    return undef;
}

sub capacity {
    my $self = shift;
    my $type = shift;
    my $old = $self->{limit}{$type};
    if (@_) {
	$self->{limit}{$type} = shift;
    }
    $old;
}

sub total_capacity {
    my $self = shift;
    my $old = $self->{limit_total};
    if (@_) {
	$self->{limit_total} = shift;
    }
    $old;
}

sub enforce_limits {
    my($self, $type) = @_;
    my $conns = $self->{conns};

    my @types = $type ? ($type) : ($self->get_types);
    for $type (@types) {
	my $limit = $self->{limit}{$type};
	next unless defined $limit;
	for my $i (reverse 0 .. @$conns - 1) {
	    next unless $conns->[$i][1] eq $type;
	    if (--$limit < 0) {
		$self->dropping(splice(@$conns, $i, 1), "$type capacity exceeded");
	    }
	}
    }

    if (defined(my $total = $self->{limit_total})) {
	while (@$conns > $total) {
	    $self->dropping(shift(@$conns), "Total capacity exceeded");
	}
    }
}

sub dropping {
    my($self, $c, $reason) = @_;
    print "DROPPING @$c [$reason]\n" if $DEBUG;
}

sub drop {
    my($self, $checker, $reason) = @_;
    if (ref($checker) ne "CODE") {
	# make it so
	if (!defined $checker) {
	    $checker = sub { 1 };  # drop all of them
	}
	elsif (_looks_like_number($checker)) {
	    my $age_limit = $checker;
	    my $time_limit = time - $age_limit;
	    $reason ||= "older than $age_limit";
	    $checker = sub { $_[3] < $time_limit };
	}
	else {
	    my $type = $checker;
	    $reason ||= "drop $type";
	    $checker = sub { $_[1] eq $type };  # match on type
	}
    }
    $reason ||= "drop";

    local $SIG{__DIE__};  # don't interfere with eval below
    local $@;
    my @c;
    for (@{$self->{conns}}) {
	my $drop;
	eval {
	    if (&$checker(@$_)) {
		$self->dropping($_, $reason);
		$drop++;
	    }
	};
	push(@c, $_) unless $drop;
    }
    @{$self->{conns}} = @c;
}

sub prune {
    my $self = shift;
    $self->drop(sub { !shift->ping }, "ping");
}

sub get_types {
    my $self = shift;
    my %t;
    $t{$_->[1]}++ for @{$self->{conns}};
    return keys %t;
}

sub get_connections {
    my($self, $type) = @_;
    my @c;
    for (@{$self->{conns}}) {
	push(@c, $_->[0]) if !$type || ($type && $type eq $_->[1]);
    }
    @c;
}

sub _looks_like_number {
    $_[0] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;
}

1;
