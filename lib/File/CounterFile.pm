# This -*-perl -*- module implements a persistent counter class.
#
# $Id: CounterFile.pm,v 0.3 1995/07/07 15:16:16 aas Exp $
#

package File::Counter;

=head1 NAME

File::Counter - Persistent counter class

=head1 SYNOPSIS

 use File::Counter;
 $c = new File::Counter "COUNTER", "aa00";

 $id = $c->inc;
 open(F, ">F$id");

=head1 DESCRIPTION

This module implements a persistent counter class.  Each counter is
represented by a separate file in the file system.  You give the file
name as a parameter to the object constructor.  The file is created if
it does not exist.

If the file name does not start with "/" or ".", then it is
interpreted as a file relative to C<$File::Counter::DEFAULT_DIR>.  You
might pass a second parameter to the constructor, that sets the
initial value for a new counter.  This parameter only takes effect
when the file is created (i.e. it does not exist before the call).

Each time you call the C<inc> method, you increment the counter value.
The new value is returned.

=head1 BUGS

It uses flock(2) to lock the counter file.  This does not always
work.  Perhaps it should use the File::Lock module.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut


use Carp;

$VERSION = $VERSION  # shut up -w
    = (qw$Revision: 0.3 $)[1];

$MAGIC           = "#COUNTER-1.0\n";   # first line in counter files
$DEFAULT_DIR     = "/usr/tmp";         # default location for counter files
$DEFAULT_INITIAL = 0;                  # default initial counter value

# Experimental overloading.  It does not work as good as expected.
#
# %OVERLOAD = ('++' => sub { my $this=shift; $this->inc; $this; },
#   	       '""' => sub { shift->value; },
# );


sub new
{
    my($class, $file, $initial) = @_;
    croak "No file specified\n" unless defined $file;

    $file = "$DEFAULT_DIR/$file" unless $file =~ /^[\.\/]/;
    $initial = $DEFAULT_INITIAL unless defined $initial;

    my $value;
    if (-e $file) {
	croak("Specified file is a directory") if -d _;
	open(F, $file) or croak("Can't open $file: $!");
	my $first_line = <F>;
	$value = <F>;
	close(F);
	croak("Bad counter magic in $file")
	    unless $first_line eq $MAGIC;
	chomp($value);
    } else {
	open(F, ">$file") or croak("Can't open $file: $!");
	print F $MAGIC;
	print F $initial, "\n";
	close(F);
	$value = $initial;
    }

    bless { file => $file, value => $value };
}


sub inc
{
    # Get a new identifier by incrementing the $count file
    my($this) = @_;
    croak("Not a ref") unless ref($this) eq "File::Counter";
    my $file = $this->{file};
    my $value;
    open(COUNT, "+<$file") or croak("Can't open $file: $!");
    flock(COUNT, 2) or croak("Can't flock: $!"); # exlusive lock
    my $magic = <COUNT>;
    if ($magic ne $MAGIC) {
	close(COUNT);
	croak("Bad counter magic '$magic' in $file");
    }
    chomp($value = <COUNT>);
    seek(COUNT, 0, 0) or croak("Can't seek to beginning: $!");
    $value++;
    print COUNT $MAGIC;
    print COUNT "$value\n";
    close(COUNT);
    $this->{value} = $value;
    $value;
}


sub value
{
    shift->{value};
}

1;
