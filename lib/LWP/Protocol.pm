#!/usr/local/bin/perl -w
#
# $Id: Protocol.pm,v 1.1 1995/06/11 23:29:43 aas Exp $

package LWP::Protocol;

=head1 NAME

LWP::Protocol -- Virtual base class for LWP protocols

=head1 DESCRIPTION

This class is the parent for all access method supported
by the LWP library. It is used internally in the library.

When creating an instance of this class using C<LWP::Protocol::new()>
you pass a URL, and you get a initialised subclass appropriate for
that access method. In other words, the constructor for this class
calls the constructor for one of its subclasses;

The LWP::Protocol classes need to override the C<request()> function
which is used to request service for an access method. The overridden
method can make use of the C<collect()> function to collect together
chunks of data received.

=head1 SEE ALSO

Inspect the LWP/file.pm and LWP/http.pm files for examples of usage.

=cut

#####################################################################

@ISA = qw(LWP::MemberMixin);
require LWP::MemberMixin;
require LWP::StatusCode;

use Carp;

$autoload = 1;

my %ImplementedBy = (); # scheme => classname

#####################################################################

=head1 METHODS AND FUNCTIONS

=head2 LWP::Protocol Constructor

Inherited by subclasses. As this is
a virtual base class this method 
should _not_ be called like:

 $prot = new LWP::Protocol()

=cut

sub new { 
    my($class) = @_;

    my $this = bless {  
        'timeout' => 0,
        'useAlarm' => 1,
    }, $class;
    $this;
}

=head1 LWP::Protocol::create

 $prot = LWP::Protocol::create($url);

Create an object of the class implementing
the protocol to handle the given scheme.
This is a function, not a method. It's more
an object factory than a constructor. This
is the function user agents should use to
access protocols.

=cut

sub create
{
    my $scheme = shift;
    my $impclass = LWP::Protocol::implementor($scheme) or croak 
        "Protocol scheme '$scheme' is not supported";

    # hand-off to scheme specific implementation sub-class
    my $prot = new $impclass, $scheme;
    return $prot;
}

=head2 LWP::Protocol::implementor

 LWP::Protocol::implementor;
 LWP::Protocol::implementor($scheme);
 LWP::Protocol::implementor($scheme, $class);

Get and/or set implementor class for a scheme.
Returns '' if the specified scheme is not supported.

=cut

sub implementor {
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
        if ($autoload) {        # autoload is back, optional
            my $package = "LWP/${scheme}.pm";
            eval {require "$package"};
            if ($@) {
                die "Cannot load package for '$scheme': $@\n";
            }
        }
        else {
            $ic = '';
        }
    }
    if ($ic) {
        $ImplementedBy{$scheme} = $ic;
    }
    $ic;
}


=head2 request()

 $response = $protocol->request($request);
 $response = $protocol->request($request, '/tmp/sss');
 $response = $protocol->request($request, \&callback, 1024);

Dispactches a request over the protocol, and returns a response
object. This method needs to be overridden in subclasses.

=cut
sub request {
    my($self, $request, $arg) = @_;

    &croak('LWP::Protocol::request() needs to be ' .
           'overridden in subclasses');
}

=head2 timeout($seconds)

Get and set the timeout value in seconds

=head2 useAlarm($yesno)

Indicates if the library is allowed to use Perl's C<alarm()>
function to implement timeouts.

=cut

sub timeout  { my $self = shift; $self->_elem('timeout',  @_); }
sub useAlarm { my $self = shift; $self->_elem('useAlarm',  @_); }

=head2 collect($arg, $response, $collector

Called to collect the content of a request,
and process it appropriately into a scalar,
file, or by calling a callback

caller can make use of Perl 5.001e's closure
mechanism

=cut
sub collect {
    my ($self, $arg, $response, $collector) = @_;
    my $content;
    if (! defined $arg) {
        # scalar
        while($content = &$collector) {
            alarm(0) if $self->useAlarm;
            &LWP::Debug::debug("read " . length $content . " bytes");
            &LWP::Debug::conns("read: $content");
            $response->addContent($content);
            alarm($self->timeout) if $self->useAlarm;
        }
    }
    elsif (!defined ref($arg)) {
        # filename
        open(OUT, ">$arg") or return
            new LWP::Response(
                 &LWP::StatusCode::RC_INTERNAL_SERVER_ERROR,
                              "Cannot write to '$arg': $!");

        while($content = &$collector) {
            alarm(0) if $self->useAlarm;
            &LWP::Debug::debug("read " . length $content . " bytes");
            &LWP::Debug::conns("read: $content");
            print OUT $content;
            alarm($self->timeout) if $self->useAlarm;
        }
        close (OUT);
    }
    elsif (ref($arg) eq 'CODE') {
        # read into callback
        while($content = &$collector) {
            alarm(0) if $self->useAlarm;
            &LWP::Debug::debug("read " . length $content . " bytes");
            &LWP::Debug::conns("read: $content");
            &$arg($this, $response, $content);
            alarm($self->timeout) if $self->useAlarm;
        }
    }
    else {
        return die "Unexpected argument '$arg'";
    }
}

#####################################################################

1;
