use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w
    eval 'exec perl -S \$0 "\$@"'
	if 0;

!GROK!THIS!

print OUT <<'!NO!SUBS!';
# $Id: dl.PL,v 1.1 1996/11/10 22:17:47 aas Exp $

=head1 NAME

dl - download to local file

=head1 SYNOPSIS

 dl <url> [<local file>]

=head1 DESCRIPTION

The I<dl> program will download the document specified by the URL
given as the first command line argument to a local file.  The local
filename used to save the document is guessed from the URL unless
specified as the second command line argument.

The I<dl> program is implemented using the I<libwww-perl> library.

=head1 AUTHOR

Gisle Aas <gisle@aas.no>

=cut

use LWP::UserAgent;
use URI::URL;
use strict;

$0 =~ s,.*/,,;  # only basename left in progname

my $url = url(shift || usage());
my $argfile = shift;

my $ua = new LWP::UserAgent;

$ua->agent("dl/0.1 " . $ua->agent);

my $req = new HTTP::Request GET => $url;

my $file;      # name of file we download into
my $length;    # total number of bytes to download
my $flength;   # formatted length
my $size = 0;  # number of bytes received
my $start_t;   # start time of download

my $shown = 0; # has we called the show() function yet

$SIG{INT} = sub { die "Interrupted\n"; };

$| = 1;  # autoflush

my $res = $ua->request($req,
  sub {
	unless($file) {
	    my $res = $_[1];
	    unless ($argfile) {
		# XXX: This does not work because the request attribute
		# is not intialized when we get this callback.  Must fix
		# this within the library
		#my $url = $res->request->url;
		
		my $base = ($url->path_components)[-1];
		$base = "index.html" unless length $base;

		# should be smarter about deciding a good file name.
		#   - get the file extention correct
		#   - content-disposal
		#   - ???
		$file = $base;
		if (-f $file && -t) {
		    print "Overwrite $file? [y] ";
		    my $ans = <STDIN>;
		    exit if !defined($ans) || !($ans =~ /^y?\n/);
		}
	    } else {
		$file = $argfile;
	    }
	    open(FILE, ">$file") || die "Can't open $file: $!";
	    $length = $res->content_length;
	    $flength = fbytes($length) if defined $length;
	    $start_t = time;
	}
	$size += length($_[0]);
	print FILE $_[0];
	if (defined $length) {
	    my $perc = $size / $length;
	    my $dur  = time - $start_t;
	    my $speed;
	    $speed = fbytes($size/$dur) . "/sec" if $dur;
	    my $secs_left = fduration($dur/$perc - $dur);
	    $perc = int($perc*100);
	    my $show = "$perc% of $flength";
	    $show .= " ($speed, $secs_left left)" if $speed;
	    show($show);
	} else {
	    show( fbytes($size) . " received");
	}
	select(undef,undef,undef, rand(3)); # slow down
  }, 128);

show("");  # clear text
print "\r";
print fbytes($size);
print " of ", fbytes($length) if defined($length);
print " received";
my $dur = time - $start_t;
if ($dur) {
    my $speed = fbytes($size/$dur) . "/sec";
    print " in ", fduration($dur), " ($speed)";
}
print "\n";

if ($res->is_success) {
    my $died = $res->header("X-Died");
    if ($died) {
	if (-t) {
	    print "Transfer aborted.  Delete $file? [n] ";
	    my $ans = <STDIN>;
	    unlink($file) if defined($ans) && $ans =~ /^y\n/;
	} else {
	    print "Transfer aborted, $file kept\n";
	}
    }
} else {
    print "$0: Can't download: ", $res->code, " ", $res->message, "\n";
}


sub fbytes
{
    my $n = int(shift);
    if ($n >= 1024 * 1024) {
	return sprintf "%.3g MB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
	return sprintf "%.3g KB", $n / 1024.0;
    } else {
	return "$n bytes";
    }
}

sub fduration
{
    use integer;
    my $secs = int(shift);
    my $hours = $secs / (60*60);
    $secs -= $hours * 60*60;
    my $mins = $secs / 60;
    $secs %= 60;
    if ($hours) {
	return "$hours hours $mins minutes";
    } elsif ($mins >= 2) {
	return "$mins minutes";
    } else {
	return "$secs seconds";
    }
}

sub show
{
    my $mess = shift;
    print "\r$mess", (" " x (70 - length $mess));
    $shown++;
}

sub usage
{
    die "Usage: $0 <url>\n";
}
!NO!SUBS!
