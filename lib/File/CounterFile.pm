# This -*-perl -*- module implements a persistent counter class.
# It should work if flock(2) works.
#
# Author: Gisle Aas, Oslonett AS
#
# $Id: CounterFile.pm,v 0.1 1995/07/07 10:56:47 aas Exp $

package Counter;

$VERSION = '1.0';

$MAGIC           = "#COUNTER-$VERSION\n";
$DEFAULT_DIR     = "/usr/tmp";
$DEFAULT_INITIAL = 0;

use Carp;

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


sub next
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
