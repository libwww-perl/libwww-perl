package URI::URL::http;
require URI::URL::_generic;
@ISA = qw(URI::URL::_generic);

sub default_port { 80 }

require Carp;

*user     = \&URI::URL::bad_method;
*password = \&URI::URL::bad_method;


# @ISA = qw(AutoLoader)      # This comment is needed by AutoSplit.
sub keywords;
sub query_form;
1;
__END__

# Note that the following two methods does not return the old
# value if they are used to set a new value.
# The risk of croaking is to high :-)  We will eventually rely
# on undefined wantarray (require perl5.004).

# Handle ...?dog+bones type of query
sub keywords {
    my $self = shift;
    $old = $self->{'query'};
    if (@_) {
	# Try to set query string
	$self->equery(join('+', map { URI::Escape::uri_escape($_, $URI::URL::reserved) } @_));
	return undef;
    }
    return undef unless defined $old;
    Carp::croak("Query is not keywords") if $old =~ /=/;
    map { URI::Escape::uri_unescape($_) } split(/\+/, $old);
}

# Handle ...?foo=bar&bar=foo type of query
sub query_form {
    my $self = shift;
    $old = $self->{'query'};
    if (@_) {
	# Try to set query string
	my @query;
	my($key,$vals);
        my $esc = $URI::URL::reserved . $URI::URL::unsafe;
	while (($key,$vals) = splice(@_, 0, 2)) {
	    $key = '' unless defined $key;
	    $key =  URI::Escape::uri_escape($key, $esc);
	    $vals = [$vals] unless ref($vals) eq 'ARRAY';
	    my $val;
	    for $val (@$vals) {
		$val = '' unless defined $val;
		$val = URI::Escape::uri_escape($val, $esc);
		push(@query, "$key=$val");
	    }
	}
	$self->equery(join('&', @query));
	return undef;
    }
    return undef unless defined $old;
    return () unless length $old;
    Carp::croak("Query is not a form") unless $old =~ /=/;
    map { s/\+/ /g; URI::Escape::uri_unescape($_) }
	 map { split(/=/, $_, 2)} split(/&/, $old);
}

1;
