# This -*-perl -*- module implements a persistent counter class.
#
# $Id: CounterFile.pm,v 0.4 1995/07/14 07:58:01 aas Exp $
#

package File::CounterFile;

=head1 NAME

File::CounterFile - Persistent counter class

=head1 SYNOPSIS

 use File::CounterFile;
 $c = new File::CounterFile "COUNTER", "aa00";

 $id = $c->inc;
 open(F, ">F$id");

=head1 DESCRIPTION

This module implements a persistent counter class.  Each counter is
represented by a separate file in the file system.  You give the file
name as a parameter to the object constructor.  The file is created if
it does not exist.

If the file name does not start with "/" or ".", then it is
interpreted as a file relative to C<$File::CounterFile::DEFAULT_DIR>.  You
might pass a second parameter to the constructor, that sets the
initial value for a new counter.  This parameter only takes effect
when the file is created (i.e. it does not exist before the call).

Each time you call the C<inc> method, you increment the counter value.
The new value is returned.

=head1 BUGS

It uses flock(2) to lock the counter file.  This does not always
work.  Perhaps it should use the File::Lock module.

=head1 INSTALLATION

Copy this file to the F<File> subdirectory of your Perl 5 library
directory (often F</usr/local/lib/perl5>).

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut


use Carp;

sub Version { $VERSION; }
$VERSION = sprintf("%d.%02d", q$Revision: 0.4 $ =~ /(\d+)\.(\d+)/);

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
    croak("Not a ref") unless ref($this) eq "File::CounterFile";
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


####################################################################
#
# S E L F   T E S T   S E C T I O N
#
#####################################################################
#
# If we're not use'd or require'd execute self-test.
# Handy for regression testing and as a quick reference :)
#
# Test is kept behind __END__ so it doesn't take uptime
# and memory  unless explicitly required. If you're working
# on the code you might find it easier to comment out the
# eval and __END__ so that error line numbers make more sense.

package main;

eval join('',<DATA>) || die $@ unless caller();

1;

__END__


$cf = "./counter-$$";  # the name for out temprary counter

# Test normal object creation and increment

$c = new File::CounterFile $cf;

$id1 = $c->inc;
$id2 = $c->inc;

$c = new File::CounterFile $cf;
$id3 = $c->inc;

die "test failed" unless ($id1 == 1 && $id2 == 2 && $id3 == 3);
unlink $cf;

# Test magic increment

$id1 = (new File::CounterFile $cf, "aa98")->inc;
$id2 = (new File::CounterFile $cf)->inc;
$id3 = (new File::CounterFile $cf)->inc;

#print "$id1 $id2 $id3\n";

die "test failed" unless ($id1 eq "aa99" && $id2 eq "ab00" && $id3 eq "ab01");
unlink $cf;


print "Selftest for File::CounterFile $File::CounterFile::VERSION ok\n";

