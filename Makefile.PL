#!perl -w

require 5.006;
use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);
use Getopt::Long qw(GetOptions);

GetOptions(\my %opt,
   'aliases',
   'no-programs|n',
   'live-tests',
) or do {
    die "Usage: $0 [--aliases] [--no-programs] [--live-tests]\n";
};

my @prog;
push(@prog, qw(lwp-request lwp-mirror lwp-rget lwp-download))
    unless $opt{'no-programs'} || grep /^LIB=/, @ARGV;

if ($opt{'aliases'} && grep(/lwp-request/, @prog)) {
    require File::Copy;
    for (qw(GET HEAD POST)) {
        File::Copy::copy("bin/lwp-request", "bin/$_") || die "Can't copy bin/$_";
        chmod(0755, "bin/$_");
        push(@prog, $_);
    }
}

system($^X, "talk-to-ourself");
flag_file("t/CAN_TALK_TO_OURSELF", $? == 0);
flag_file("t/live/ENABLED", $opt{'live-tests'});

WriteMakefile(
    NAME => 'LWP',
    DISTNAME => 'libwww-perl',
    VERSION_FROM => 'lib/LWP.pm',
    EXE_FILES => [ map "bin/$_", @prog ],
    PREREQ_PM => {
        'URI'            => "1.10",
        'MIME::Base64'   => "2.1",
        'Net::FTP'       => "2.58",
        'HTML::Tagset'   => 0,
        'HTML::Parser'   => "3.33",
        'Digest::MD5'    => 0,
        'Compress::Zlib' => "1.10",
    },
    clean => { FILES => join(" ", map "bin/$_", grep /^[A-Z]+$/, @prog) },
);
exit;


sub MY::test
{
    q(
TEST_VERBOSE=0

test : pure_all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

);
}


sub flag_file {
    my($file, $create) = @_;
    if ($create) {
        open(my $fh, ">", $file) || die "Can't create $file: $!";
    }
    else {
        unlink($file);
    }
}
