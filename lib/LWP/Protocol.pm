#
# $Id: Protocol.pm,v 1.12 1995/09/04 20:44:38 aas Exp $

package LWP::Protocol;

=head1 NAME

LWP::Protocol - Virtual base class for LWP protocols

=head1 DESCRIPTION

This class is the parent for all access method supported by the LWP
library. It is used internally in the library.

When creating an instance of this class using C<LWP::Protocol::new()>
you pass a URL, and you get a initialised subclass appropriate for
that access method. In other words, the constructor for this class
calls the constructor for one of its subclasses;

The LWP::Protocol classes need to override the C<request()> function
which is used to request service for an access method. The overridden
method can make use of the C<collect()> function to collect together
chunks of data received.

=head1 SEE ALSO

Inspect the F<LWP/Protocol/file.pm> and F<LWP/Protocol/http.pm> files
for examples of usage.

=cut

#####################################################################

use Carp;

require HTTP::Status;
require LWP::MemberMixin;

@ISA = qw(LWP::MemberMixin);

$autoload = 1;

my %ImplementedBy = (); # scheme => classname


#####################################################################

=head1 METHODS AND FUNCTIONS

=head2 new

The LWP::Protocol constructor is inherited by subclasses. As this is a
virtual base class this method should B<not> be called like:

 $prot = new LWP::Protocol()

=cut

sub new
{ 
    my($class) = @_;

    my $self = bless {  
        'timeout' => 0,
        'useAlarm' => 1,
    }, $class;
    $self;
}


=head2 LWP::Protocol::create($url)

Create an object of the class implementing the protocol to handle the
given scheme. This is a function, not a method. It is more an object
factory than a constructor. This is the function user agents should
use to access protocols.

=cut

sub create
{
    my $scheme = shift;
    my $impclass = LWP::Protocol::implementor($scheme) or
        croak "Protocol scheme '$scheme' is not supported";

    # hand-off to scheme specific implementation sub-class
    my $prot = new $impclass, $scheme;
    return $prot;
}


=head2 LWP::Protocol::implementor

 LWP::Protocol::implementor($scheme);
 LWP::Protocol::implementor($scheme, $class);

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
    no strict qw(refs);
    # check we actually have one for the scheme:
    unless (defined @{"${ic}::ISA"}) {
        if ($autoload) {
            my $package = "LWP/Protocol/${scheme}.pm";
            eval {require "$package"};
            if ($@) {
                if ($@ =~ /^Can't locate/) { #' #emacs get confused by '
                    $ic = '';
                } else {
                    die "$@\n";
                }
            }
        } else {
            $ic = '';
        }
    }
    $ImplementedBy{$scheme} = $ic if $ic;
    $ic;
}


=head2 request(...)

 $response = $protocol->request($request, $proxy, undef);
 $response = $protocol->request($request, $proxy, '/tmp/sss');
 $response = $protocol->request($request, $proxy, \&callback, 1024);

Dispactches a request over the protocol, and returns a response
object. This method needs to be overridden in subclasses.

=cut

sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    croak 'LWP::Protocol::request() needs to be overridden in subclasses';
}


=head2 timeout($seconds)

Get and set the timeout value in seconds


=head2 useAlarm($yesno)

Indicates if the library is allowed to use the core C<alarm()>
function to implement timeouts.

=cut

sub timeout  { shift->_elem('timeout',  @_); }
sub useAlarm { shift->_elem('useAlarm', @_); }


=head2 collect($arg, $response, $collector)

Called to collect the content of a request, and process it
appropriately into a scalar, file, or by calling a callback.

Note: We will only use the callback if $response->isSuccess().  This
avoids sendig content data for redirects and authentization responses
to the callback which would be confusing.

=cut

sub collect
{
    my ($self, $arg, $response, $collector) = @_;
    my $content;
    if (! defined $arg) {
        # scalar
        while ($content = &$collector, length $$content) {
            alarm(0) if $self->useAlarm;
            LWP::Debug::debug("read " . length $$content . " bytes");
            $response->addContent($$content);
            alarm($self->timeout) if $self->useAlarm;
        }
    }
    elsif (!defined ref($arg)) {
        # filename
        open(OUT, ">$arg") or
            return new HTTP::Response
                          &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
                          "Cannot write to '$arg': $!";

        while ($content = &$collector, length $$content) {
            alarm(0) if $self->useAlarm;
            LWP::Debug::debug("read " . length $content . " bytes");
            print OUT $$content;
            alarm($self->timeout) if $self->useAlarm;
        }
        close(OUT);
    }
    elsif (ref($arg) eq 'CODE') {
        # read into callback
        while ($content = &$collector, length $$content) {
            alarm(0) if $self->useAlarm;
            LWP::Debug::debug("read " . length $$content . " bytes");
	    if ($response->isSuccess) {
		&$arg($$content, $response, $self);
	    } else {
		$response->addContent($$content);
	    }
            alarm($self->timeout) if $self->useAlarm;
        }
    }
    else {
        return new HTTP::Response &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
                                  "Unexpected collect argument  '$arg'";
    }
    $response;
}

1;
