# This -*-perl -*- module implements a persistent counter class.
#
# $Id: CounterFile.pm,v 0.2 1995/07/07 11:29:37 aas Exp $
#

package Counter;

=head1 NAME

Counter - Persistent counter class

=head1 SYNOPSIS

 use Counter;
 $c = new Counter "COUNTER", "aa00";

 $id = $c->inc;
 open(F, ">F$id");

=head1 DESCRIPTION

This module implements a persistent counter class.  Each counter is
represented by a separate file in the file system.  You give the file
name as a parameter to the object constructor.  The file is created if
it does not exist.

If the file name does not start with "/" or ".", then it is
interpreted as a file relative to C<$Counter::DEFAULT_DIR>.  You might
pass a second parameter to the constructor, that sets the initial
value for a new counter.  This parameter only takes effect when the
file is created (i.e. it does not exist before the call).

Each time you call the C<inc> method, you increment the counter value.
The new value is returned.

=head1 BUGS

It uses flock(2) to lock the counter file.  This does not always
work.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut


use Carp;

$VERSION = '1.0';

$MAGIC           = "#COUNTER-$VERSION\n";
$DEFAULT_DIR     = "/usr/tmp";
$DEFAULT_INITIAL = 0;


sub new
{
    my($class, $file, $initial) = @_;
    croak "No file specified\n" unless defined $file;

    $file = "$DEFAULT_DIR/$file" unless $file =~ /^[\.\/]/;
    $initial = $DEFAULT_INITIAL unless defined $initial;

    if (-e $file) {
	croak("Specified file is a directory") if -d _;
	open(F, $file) or croak("Can't open $file: $!");
	my $first_line = <F>;
	close(F);
	croak("Bad magic in $file")
	    unless $first_line eq $MAGIC;
    } else {
	open(F, ">$file") or croak("Can't open $file: $!");
	print F $MAGIC;
	print F $initial, "\n";
	close(F);
    }

    bless { file => $file };
}


sub inc
{
    # Get a new identifier by incrementing the $count file
    my($this) = @_;
    croak("Not a ref") unless ref($this) eq "Counter";
    my $file = $this->{file};
    my $id = 0;
    open(COUNT, "+<$file") or croak("Can't open $file: $!");
    flock(COUNT, 2) or croak("Can't flock: $!"); # exlusive lock
    my $magic = <COUNT>;
    if ($magic ne $MAGIC) {
	close(COUNT);
	croak("Bad magic '$magic' in $file");
    }
    chomp($id = <COUNT>);
    seek(COUNT, 0, 0) or croak("Can't seek to beginning: $!");
    $id++;
    print COUNT $MAGIC;
    print COUNT "$id\n";
    close(COUNT);
    $id;
}

1;
