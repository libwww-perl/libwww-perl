# $Id: Protocol.pm,v 1.21 1996/05/08 16:26:49 aas Exp $

package LWP::Protocol;

=head1 NAME

LWP::Protocol - Virtual base class for LWP protocols

=head1 DESCRIPTION

This class is the parent for all access method supported by the LWP
library. It is used internally in the library.

When creating an instance of this class using C<LWP::Protocol::new()>
you pass a URL, and you get an initialised subclass appropriate for
that access method. In other words, the constructor for this class
calls the constructor for one of its subclasses.

The LWP::Protocol sub classes need to override the request() method
which is used to service a request for that specific protocol. The
overridden method can make use of the collect() function to collect
together chunks of data as it is received.

=head1 SEE ALSO

Inspect the F<LWP/Protocol/file.pm> and F<LWP/Protocol/http.pm> files
for examples of usage.

=head1 METHODS AND FUNCTIONS

=cut

#####################################################################

require LWP::MemberMixin;
@ISA = qw(LWP::MemberMixin);

use strict;
use Carp ();
use HTTP::Status 'RC_INTERNAL_SERVER_ERROR';

my %ImplementedBy = (); # scheme => classname


=head2 new HTTP::Protocol

The LWP::Protocol constructor is inherited by subclasses. As this is a
virtual base class this method should B<not> be called directly.

=cut

sub new
{
    my($class) = @_;

    my $self = bless {
	'timeout' => 0,
	'use_alarm' => 1,
    }, $class;
    $self;
}


=head2 $prot = LWP::Protocol::create($url)

Create an object of the class implementing the protocol to handle the
given scheme. This is a function, not a method. It is more an object
factory than a constructor. This is the function user agents should
use to access protocols.

=cut

sub create
{
    my $scheme = shift;
    my $impclass = LWP::Protocol::implementor($scheme) or
	Carp::croak("Protocol scheme '$scheme' is not supported");

    # hand-off to scheme specific implementation sub-class
    my $prot = new $impclass, $scheme;
    return $prot;
}


=head2 $class = LWP::Protocol::implementor($scheme, [$class])

Get and/or set implementor class for a scheme.  Returns '' if the
specified scheme is not supported.

=cut

sub implementor
{
    my($scheme, $impclass) = @_;

    if ($impclass) {
	$ImplementedBy{$scheme} = $impclass;
    }
    my $ic = $ImplementedBy{$scheme};
    return $ic if $ic;

    # scheme not yet known, look for a 'use'd implementation
    $ic = "LWP::Protocol::$scheme";  # default location
    $ic = "LWP::Protocol::nntp" if $scheme eq 'news'; #XXX ugly hack
    no strict qw(refs);
    # check we actually have one for the scheme:
    unless (defined @{"${ic}::ISA"}) {
	my $package = "$ic.pm";
	$package =~ s|::|/|g;
	eval { require "$package" };
	if ($@) {
	    if ($@ =~ /^Can't locate/) { #' #emacs get confused by '
		$ic = '';
	    } else {
		die "$@\n";
	    }
	}
    }
    $ImplementedBy{$scheme} = $ic if $ic;
    $ic;
}


=head2 $prot->request(...)

 $response = $protocol->request($request, $proxy, undef);
 $response = $protocol->request($request, $proxy, '/tmp/sss');
 $response = $protocol->request($request, $proxy, \&callback, 1024);

Dispactches a request over the protocol, and returns a response
object. This method needs to be overridden in subclasses.  Referer to
L<LWP::UserAgent> for description of the arguments.

=cut

sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    Carp::croak('LWP::Protocol::request() needs to be overridden in subclasses');
}


=head2 timeout($seconds)

Get and set the timeout value in seconds


=head2 use_alarm($yesno)

Indicates if the library is allowed to use the core alarm()
function to implement timeouts.

=cut

sub timeout  { shift->_elem('timeout',  @_); }
sub use_alarm { shift->_elem('use_alarm', @_); }


=head2 collect($arg, $response, $collector)

Called to collect the content of a request, and process it
appropriately into a scalar, file, or by calling a callback.

Note: We will only use the callback or file argument if
$response->is_success().  This avoids sendig content data for
redirects and authentization responses to the callback which would be
confusing.

=cut

sub collect
{
    my ($self, $arg, $response, $collector) = @_;
    my $content;
    my($use_alarm, $timeout) = @{$self}{'use_alarm', 'timeout'};

    if (!defined($arg) || !$response->is_success) {
	# scalar
	while ($content = &$collector, length $$content) {
	    alarm(0) if $use_alarm;
	    LWP::Debug::debug("read " . length($$content) . " bytes");
	    $response->add_content($$content);
	    alarm($timeout) if $use_alarm;
	}
    }
    elsif (!ref($arg)) {
	# filename
	open(OUT, ">$arg") or
	    return new HTTP::Response RC_INTERNAL_SERVER_ERROR,
			  "Cannot write to '$arg': $!";
        local($\) = ""; # ensure standard $OUTPUT_RECORD_SEPARATOR
	while ($content = &$collector, length $$content) {
	    alarm(0) if $use_alarm;
	    LWP::Debug::debug("read " . length($$content) . " bytes");
	    print OUT $$content;
	    alarm($timeout) if $use_alarm;
	}
	close(OUT);
    }
    elsif (ref($arg) eq 'CODE') {
	# read into callback
	while ($content = &$collector, length $$content) {
	    alarm(0) if $use_alarm;
	    LWP::Debug::debug("read " . length($$content) . " bytes");
            eval {
		&$arg($$content, $response, $self);
	    };
	    if ($@) {
	        chomp($@);
		$response->header('X-Died' => $@);
		last;
	    }
	    alarm($timeout) if $use_alarm
	}
    }
    else {
	return new HTTP::Response RC_INTERNAL_SERVER_ERROR,
				  "Unexpected collect argument  '$arg'";
    }
    $response;
}


sub collect_once
{
    my($self, $arg, $response) = @_;
    my $content = \ $_[3];
    my $first = 1;
    $self->collect($arg, $response, sub {
	return $content if $first--;
	return \ "";
    });
}

1;
