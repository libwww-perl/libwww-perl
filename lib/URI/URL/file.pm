package URI::URL::file;
require URI::URL::_generic;
@ISA = qw(URI::URL::_generic);

require Carp;
require Config;

# First we try to determine what kind of system we run on
my $os = $Config::Config{'osname'};
OS: {
    $ostype = 'vms', last if $os eq 'VMS';
    $ostype = 'dos', last if $os =~ /^(?:os2|mswin32|msdos)$/i;
    $ostype = 'mac', last if $os eq "Mac";
    $ostype = 'unix';  # The default
}
# If you add more types to this list, remember to add a xxx_path method
# as well.


# This is the BNF found in RFC 1738:
#
# fileurl        = "file://" [ host | "localhost" ] "/" fpath
# fpath          = fsegment *[ "/" fsegment ]
# fsegment       = *[ uchar | "?" | ":" | "@" | "&" | "=" ]
# Note that fsegment can contain '?' (query) but not ';' (param)

sub newlocal {
    my($class, $path) = @_;

    Carp::Croak("Only implemented for Unix") unless $ostype eq "unix";
    # XXX: Should implement the same thing for other systems

    my $url = new URI::URL "file:";
    unless (defined $path and $path =~ m:^/:) {
        require Cwd;
        my $cwd = Cwd::fastcwd();
        $cwd =~ s:/?$:/:; # force trailing slash on dir
        $path = (defined $path) ? $cwd . $path : $cwd;
    }
    $url->path($path);
    $url;
}

sub _parse {
    my($self, $init) = @_;
    # The file URL can't have query
    $self->URI::URL::_generic::_parse($init, qw(netloc path params frag));
    1;
}

# Returns a path suitable for use on the local system
eval <<"EOT";
sub local_path
{
    shift->${ostype}_path;
}
EOT
die $@ if $@;


sub unix_path
{
    my $self = shift;
    my @p;
    for ($self->path_components) {
	Carp::croak("Path component contains '/'") if m|/|;
	push(@p, $_);
    }
    unshift(@p, '') if $self->absolute_path;
    my $p = join('/', @p);
}

sub dos_path
{
    my $self = shift;
    my @p;
    for ($self->path_components) {
	Carp::croak("Path component contains '/' or '\\'") if m|[/\\]|;
	push(@p, uc $_);
    }
    unshift(@p, '') if $self->absolute_path;
    my $p = join("\\", @p);
    $p =~ s/^\\([A-Z]:)/$1/;  # Fix drive letter specification
    $p;
}

sub mac_path
{
    my $self = shift;
    my @p;
    for ($self->path_components) {
	Carp::croak("Path component contains ':'") if /:/;
	push(@p, $_);
    }
    unshift(@p, '') unless $self->absolute_path;  # Macs to it this way
    join(':', @p);
}

sub vms_path
{
    # This is implemented based on what RFC1738 (sec 3.10) says in the
    # VMS file example:
    #
    #  DISK$USER:[MY.NOTES]NOTE123456.TXT
    #
    #      that might become
    #
    #  file:/disk$user/my/notes/note12345.txt
    #
    # BEWARE: I don't have a VMS machine myself so this is pure guesswork

    my $self = shift;
    my @p = $self->path_components;
    # First I assume there must be a dollar in a disk spesification
    my $p = '';
    $p = uc(shift(@p)) . ":"  if @p && $p[0] =~ /\$/;
    my $file = pop(@p);
    $p .= "[" . join(".", map{uc($_)} @p) . "]" if @p;
    $p .= uc $file;
    # XXX: How is an absolute path different from a relative one??
    $p =~ s/\[/[./ unless $self->absolute_path;  # Like this???
    # XXX: How is a directory denoted??
    $p;
}

sub query { Carp::croak("Illegal method for file URLs"); }
*equery = \&query;

1;
