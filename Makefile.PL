# This -*- perl -*- script writes the Makefile for libwww-perl

require 5.005;
use strict;
use ExtUtils::MakeMaker qw(WriteMakefile prompt);
use Config qw(%Config);

#--- Configuration section ---

my @programs_to_install = qw(lwp-request lwp-mirror lwp-rget lwp-download);
my @request_aliases     = qw(GET HEAD POST);

#--- End Configuration - You should not have to change anything below this line


# Allow us to suppress all program installation with the -n (library only)
# option.  This is for those that don't want to mess with the configuration
# section of this file.
use Getopt::Std;
use vars qw($opt_n);
unless (getopts("n")) {
    die "Usage: $0 [-n]\n";
}
@programs_to_install = () if $opt_n || grep /^LIB=/, @ARGV;

# Check if we should try to run tests that talk to ourself
system(qq("$^X" talk-to-ourself));
if ($?) {
    print <<EOT;

You appear to have a misconfigured system, so I will disable tests
that try to talk HTTP to a local server.
EOT
    unlink("t/CAN_TALK_TO_OURSELF");
}
else {
    open(CAN_TALK_TO_OURSELF, ">t/CAN_TALK_TO_OURSELF") || die "Can't create CAN_TALK_TO_OURSELF: $!";
    close(CAN_TALK_TO_OURSELF);
}

# Check if we should try to run the live tests
open(CHANGES, "Changes") || die "Can't open Changes: $!";
my $release_date;
while (<CHANGES>) {
    if (/^(\d{4}-\d{2}-\d{2})\D/) {
        $release_date = $1;
	last;
    }
}
close(CHANGES);
die "Can't figure out release date" unless $release_date;
#print "Release date: $release_date\n";

my $some_time_ago = sprintf "%04d-%02d-%02d",
          sub { ($_[5]+1900, $_[4]+1, $_[3])}->(localtime(time - 45 * 24*60*60));
if ($some_time_ago lt $release_date) {
    # Check if we have internet connection
    require IO::Socket;
    my $s = IO::Socket::INET->new(PeerAddr => "www.google.com:80",
				  Timeout  => 10,
				 );
    if ($s) {
	# XXX could try to send a GET to it???
	close($s);

	print <<EOT;

You appear to be directly connected to the Internet.  I have some tests
that tries to access some sites on the net to verify that the new HTTP/1.1
support works as it should.

EOT

        if (prompt("Do you want to enable these tests?", "y") =~ /^y/i) {
	    open(ENABLED, ">t/live/ENABLED") || die "Can't enable: $!";
	    close(ENABLED);
	}
	else {
	    unlink("t/live/ENABLED");
	}
    }
}

if (@programs_to_install) {
    print <<EOT;

This package comes with some sample programs that I can try
to install in $Config{installscript}.

   Note that you can avoid these questions by passing
   the '-n' option to 'Makefile.PL'.

EOT
    my @tmp;
    for (@programs_to_install) {
	if (prompt("Do you want to install $_?", "y") =~ /^y/) {
	    push(@tmp, $_);
	}
    }
    @programs_to_install = @tmp;
}

if (grep($_ eq 'lwp-request', @programs_to_install) && @request_aliases) {
    print <<EOT;

The lwp-request program will use the name it is invoked with to
determine what HTTP method to use.  I can set up alias for the most
common HTTP methods.  These alias are also installed in
$Config{installscript}.

EOT
    my @tmp;
    for my $alias (@request_aliases) {
	my $default = "n";
	if (prompt("Do you want to install the $alias alias?", $default) =~ /^y/) {
	    push(@tmp, $alias);
	}
    }
    @request_aliases = @tmp;
}
else {
    @request_aliases = ();
}

if (@request_aliases) {
    require File::Copy;
    for (@request_aliases) {
        File::Copy::copy("bin/lwp-request", "bin/$_") || die "Can't copy bin/$_";
	chmod(0755, "bin/$_");
	push(@programs_to_install, $_);
    }
}


# Ok, now it is time to really generate the Makefile

WriteMakefile(
   NAME          => 'LWP',
   DISTNAME      => 'libwww-perl',
   VERSION_FROM  => 'lib/LWP.pm',
   EXE_FILES     => [ map "bin/$_", @programs_to_install ],
   PREREQ_PM     => { 'URI'              => "1.10",
                      'MIME::Base64'     => "2.1",
                      'Net::FTP'         => "2.58",
                      'HTML::Tagset'     => 0,
                      'HTML::Parser'     => "3.33",
                      'Digest::MD5'      => 0,
                      'Compress::Zlib'   => "1.10",
                     },
   'clean'       => { FILES => join(" ", map "bin/$_", @request_aliases) },
   'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);



package MY;

# What happens when we say 'make test'
sub test
{
    q(
TEST_VERBOSE=0

test: all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

);
}


# Determine things that should *not* be installed
sub libscan
{
    my($self, $path) = @_;
    return '' if $path =~ m/\.(pl|dtd|sgml)$/;
    return '' if $path =~ m:\bCVS/:;
    return '' if $path =~ m/~$/;
    $path;
}

# Pass libwww-perl version number to pod2man
sub manifypods
{
    my $self = shift;
    my $ver = $self->{VERSION} || "";
    local($_) = $self->SUPER::manifypods(@_);
    s/pod2man\s*$/pod2man --release libwww-perl-$ver/m;
    $_;
}
