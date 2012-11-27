#!perl -w

require 5.008001;
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long qw(GetOptions);

GetOptions(\my %opt,
   'aliases',
   'no-programs|n',
   'live-tests',
   'jigsaw-tests',
) or do {
    die "Usage: $0 [--aliases] [--no-programs] [--live-tests] [--jigsaw-tests]\n";
};

my @prog;
push(@prog, qw(lwp-request lwp-mirror lwp-download lwp-dump))
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
flag_file("t/live/jigsaw/ENABLED", $opt{'jigsaw-tests'});

WriteMakefile(
    NAME => 'LWP',
    DISTNAME => 'libwww-perl',
    VERSION_FROM => 'lib/LWP.pm',
    ABSTRACT => 'The World-Wide Web library for Perl',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    EXE_FILES => [ map "bin/$_", @prog ],
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.008001,
    PREREQ_PM => {
        'Digest::MD5' => 0,
        'Encode' => "2.12",
        'Encode::Locale' => 0,
        'File::Listing' => 6,
        'HTML::Entities' => 0,
        'HTML::HeadParser' => 0,
        'HTTP::Cookies' => 6,
        'HTTP::Daemon' => 6,
        'HTTP::Date' => 6,
        'HTTP::Negotiate' => 6,
        'HTTP::Request' => 6,
        'HTTP::Request::Common' => 6,
        'HTTP::Response' => 6,
        'HTTP::Status' => 6,
        'IO::Select' => 0,
        'IO::Socket' => 0,
        'LWP::MediaTypes' => 6,
        'MIME::Base64' => "2.1",
        'Net::FTP' => "2.58",
        'Net::HTTP' => "6.04",
        'URI' => "1.10",
        'URI::Escape' => 0,
        'WWW::RobotRules' => 6,
    },
    META_MERGE => {
        recommends => {
	    'LWP::Protocol::https' => '6.02',
            'Authen::NTLM' => "1.02",
            'Data::Dump' => 0,
        },
	resources => {
            repository => 'https://github.com/libwww-perl/libwww-perl',
	    MailingList => 'mailto:libwww@perl.org',
        }
    },
    clean => { FILES => join(" ", map "bin/$_", grep /^[A-Z]+$/, @prog) },
);



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
    my $developer = -f ".gitignore";
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
