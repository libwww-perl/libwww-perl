package HTTP::MessageParts;

use strict;
require HTTP::Message;

sub HTTP::Message::parent {
    shift->_elem('_parent',  @_);
}

sub HTTP::Message::_content {
    die "NYI";
}

sub HTTP::Message::_parts {
    my $self = shift;
    my $ct = $self->content_type;
    if ($ct =~ m,^multipart/,) {
	require HTTP::Headers::Util;
	my @h = HTTP::Headers::Util::split_header_words($self->header("Content-Type"));
	die "Assert" unless @h;
	my %h = @{$h[0]};
	if (defined(my $b = $h{boundary})) {
	    my $str = $self->{_content};
	    $str =~ s/\r?\n--\Q$b\E--\r?\n.*//s;
	    if ($str =~ s/(^|.*?\r?\n)--\Q$b\E\r?\n//s) {
		$self->{_parts} = [map HTTP::Message->new(_parse_msg($_)),
				   split(/\r?\n--\Q$b\E\r?\n/, $str)]
	    }
	}
    }
    elsif (0 && $ct eq "message/http") {
        die "NYI";
    }
    elsif ($ct =~ m,^message/,) {
	$self->{_parts} =
	    [HTTP::Message->new(_parse_msg($self->{_content}))];
    }

    $self->{_parts} ||= [];
}

sub _parse_msg {
    my $str = shift;
    my @hdr;
    while (1) {
	if ($str =~ s/^([^ \t:]+)[ \t]*: ?(.*)\n?//) {
	    push(@hdr, $1, $2);
	    $hdr[-1] =~ s/\r\z//;
	}
	elsif (@hdr && $str =~ s/^([ \t].*)\n?//) {
	    $hdr[-1] .= "\n$1";
	    $hdr[-1] =~ s/\r\z//;
	}
	else {
	    $str =~ s/^\r?\n//;
	    last;
	}
    }

    return (HTTP::Headers->new(@hdr), $str);
}

sub HTTP::Message::parts {
    my $self = shift;
    if (defined(wantarray) && !exists $self->{_parts}) {
	$self->_parts;
    }
    my $old = $self->{_parts};
    if (@_) {
	$self->{_parts} = [@_];
	delete $self->{_content};
    }
    return @$old if wantarray;
    return $old->[0];
}

sub HTTP::Message::add_part {
    my $self = shift;
    die "NYI";
}

1;
