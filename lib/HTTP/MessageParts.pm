package HTTP::MessageParts;

use strict;
require HTTP::Message;

my $CRLF = "\015\012";   # "\r\n" is not portable

sub HTTP::Message::parent {
    shift->_elem('_parent',  @_);
}

sub HTTP::Message::_content {
    my $self = shift;
    my $ct = $self->content_type;
    if ($ct =~ m,^message/,) {
	$self->{_content} = $self->{_parts}[0]->as_string($CRLF);
	return;
    }

    my @parts = map $_->as_string($CRLF), @{$self->{_parts}};
    my $boundary = "XXXXXXXX";  # XXX
    $self->{_content} = "--$boundary\n" .
	                join("\n--$boundary\n", @parts) .
			"\n--$boundary--\n";
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
    elsif ($ct eq "message/http") {
	my $str = $self->{_content};
	my $m;
	if ($str =~ s,^(HTTP/.*)\n,,) {
	    my($proto, $code, $msg) = split(' ', $1);
	    require HTTP::Response;
	    $m = HTTP::Response->new($code, $msg, _parse_msg($str));
	    $m->protocol($proto);
	}
	elsif ($str =~ s,^(.*)\n,,) {
	    my($method, $uri, $proto) = split(' ', $1);
	    require HTTP::Request;
	    $m = HTTP::Request->new($method, $uri, _parse_msg($str));
	    $m->protocol($proto) if $proto;
	}
	$self->{_parts} = [$m] if $m;
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
