package LWP::Debug::TraceHTTP;

# Just call:
#
#   require LWP::Debug::TraceHTTP;
#   LWP::Protocol::implementor('http', 'LWP::Debug::TraceHTTP');
#
# to use this module to trace all calls to the HTTP socket object in
# programs that use LWP.

use strict;

use base 'LWP::Protocol::http';

package LWP::Debug::TraceHTTP::Socket;

use Data::Dump qw(pp);
use Term::ANSIColor qw(YELLOW CYAN RESET);

sub dumpav {
    return "(" . pp(@_) . ")" if @_ == 1;
    return pp(@_);
}

sub dumpkv {
    return dumpav(@_) if @_ % 2;
    my %h = @_;
    my $str = pp(\%h);
    $str =~ s/^\{/(/ && $str =~ s/\}\z/)/;
    return $str;
}

sub new {
    my $class = shift;
    print YELLOW, "$class->new", dumpkv(@_), RESET;
    my $sock = LWP::Protocol::http::Socket->new(@_);
    if ($sock) {
        print " ==> ", CYAN, "\$sock\n", RESET;
        return bless { sock => $sock }, $class;
    }
    else {
        print " ==> ", CYAN, "undef\n", RESET;
        return undef;
    }
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
    print YELLOW, "\$sock->", $method, dumpav(@_), RESET;
    if (!defined wantarray) {
        print ";\n";
        $self->{sock}->$method(@_);
    }
    elsif (wantarray) {
        my @s = $self->{sock}->$method(@_);
        if ($method eq "read_response_headers" || "get_trailers") {
            print " ==> ", CYAN, dumpkv(@s), RESET, "\n";
        }
        else {
            print " ==> ", CYAN, dumpav(@s), RESET, "\n";
        }
        return @s;
    }
    else {
        my $s = $self->{sock}->$method(@_);
        print " ==> ", CYAN, pp($s), RESET, "\n";
        return $s;
    }
}

sub read_entity_body {
    my $self = shift;
    print YELLOW, "read_entity_body", RESET;
    my $s = $self->{sock}->read_entity_body(@_);
    if ($s) {
        print YELLOW, "(", CYAN, pp($_[0]);
        print YELLOW, ", ", pp($_[1]), ")", RESET;
    }
    else {
        print YELLOW, dumpav(@_), RESET;
    }
    print " ==> ", CYAN, pp($s), RESET, "\n";
}

1;
