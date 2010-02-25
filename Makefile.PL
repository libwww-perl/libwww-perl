#!perl -w

require 5.006;
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long qw(GetOptions);

GetOptions(\my %opt,
   'aliases',
   'no-programs|n',
   'live-tests',
) or do {
    die "Usage: $0 [--aliases] [--no-programs] [--live-tests]\n";
};

my @prog;
push(@prog, qw(lwp-request lwp-mirror lwp-rget lwp-download lwp-dump))
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
    ABSTRACT => 'The World-Wide Web library for Perl',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    EXE_FILES => [ map "bin/$_", @prog ],
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.006,
    PREREQ_PM => {
        'URI'            => "1.10",
        'MIME::Base64'   => "2.1",
        'Net::FTP'       => "2.58",
        'HTML::Tagset'   => 0,
        'HTML::Parser'   => "3.33",
        'Digest::MD5'    => 0,
        'Compress::Raw::Zlib'        => 0,
        'IO::Compress::Gzip'         => 0,
        'IO::Compress::Deflate'      => 0,
        'IO::Uncompress::Gunzip'     => 0,
        'IO::Uncompress::Inflate'    => 0,
        'IO::Uncompress::RawInflate' => 0,
    },
    META_MERGE => {
        recommends => {
            'Crypt::SSLeay' => 0,
        },
	resources => {
            repository => 'http://github.com/gisle/libwww-perl',
	    MailingList => 'mailto:libwww@perl.org',
        }
    },
    clean => { FILES => join(" ", map "bin/$_", grep /^[A-Z]+$/, @prog) },
);

if($] >= 5.008 && !(eval { require Encode; defined(Encode::decode("UTF-8", "\xff")) })) {
    warn "\nYou lack a working Encode module, and so you will miss out on\n".
           "lots of character set goodness from LWP.  However, your perl is\n".
           "sufficiently recent to support it.  It is recommended that you\n".
           "install the latest Encode from CPAN.\n\n";
}



sub MY::test
{
    q(
TEST_VERBOSE=0

test : pure_all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

test_hudson : pure_all
	$(FULLPERL) t/TEST $(TEST_VERBOSE) --formatter=TAP::Formatter::JUnit

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

BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f "NOTES.txt";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
