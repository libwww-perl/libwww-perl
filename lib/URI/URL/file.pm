package URI::URL::file;
@ISA = qw(URI::URL::_generic);

require Carp;

# fileurl        = "file://" [ host | "localhost" ] "/" fpath
# fpath          = fsegment *[ "/" fsegment ]
# fsegment       = *[ uchar | "?" | ":" | "@" | "&" | "=" ]
# Note that fsegment can contain '?' (query) but not ';' (param)

sub _parse {
    my($self, $init) = @_;
    # allow the generic parser to do the bulk of the work
    $self->URI::URL::_generic::_parse($init);
    # then just deal with the effect of rare stray '?'s
    if (defined $self->{'query'}){
        $self->{'path'} .= '?' . $self->{'query'};
        delete $self->{'query'};
    }
    1;
}

sub _esc_path
{
    my($self, $text) = @_;
    $text =~ s/([^-a-zA-Z\d\$_.+!*'(),%?:@&=\/])/$URI::Escape::escapes{$1}/oeg; #' fix emacs
    $text;
}

sub query { Carp::croak("Illegal method for file URLs"); }

1;
