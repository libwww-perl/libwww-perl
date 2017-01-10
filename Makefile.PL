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

my $tests = 't/base/*.t t/html/*.t t/robot/*.t t/local/*.t t/net/*.t';
$tests .= ' t/live/*.t'
  if $opt{'live-tests'};
$tests .= ' t/live/jigsaw/*.t'
  if $opt{'jigsaw-tests'};

my %WriteMakefileArgs = (
    NAME => 'LWP',
    DISTNAME => 'libwww-perl',
    VERSION_FROM => 'lib/LWP.pm',
    ABSTRACT => 'The World-Wide Web library for Perl',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    EXE_FILES => [ map "bin/$_", @prog ],
    LICENSE => 'perl_5',
    MIN_PERL_VERSION => 5.008001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Getopt::Long'        => 0,
        'File::Copy'          => 0,
    },
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
        'Net::HTTP' => "6.07",
        'URI' => "1.10",
        'URI::Escape' => 0,
        'WWW::RobotRules' => 6,
    },
    TEST_REQUIRES => {
        'Test::Fatal' => '0',
        'Test::More' => '0',
        'Test::RequiresInternet' => '0',
        'FindBin' => '0',
        # 'Config' => 0,        # not indexed
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        prereqs => {
            runtime => {
                suggests => {
                    'LWP::Protocol::https' => '6.02',
                    'Authen::NTLM' => "1.02",
                    'IO::Socket::INET' => '0',
                },
            },
        },
        resources => {
            repository => {
                 url => 'https://github.com/libwww-perl/libwww-perl.git',
                 web => 'https://github.com/libwww-perl/libwww-perl',
                 type => 'git',
            },
            bugtracker => {
                 mailto => 'bug-libwww-perl@rt.cpan.org',
                 web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=libwww-perl',
            },
            x_MailingList => 'mailto:libwww@perl.org',
            x_IRC => 'irc://irc.perl.org/#lwp',
        },
        x_authority => 'cpan:LWWWP',
    },
    clean => { FILES => join(" ", map "bin/$_", grep /^[A-Z]+$/, @prog) },
    test => { TESTS => $tests },
);

{
    # compatibility with older versions of MakeMaker
    my $developer = -f ".gitignore";

    die 'need to do a merge with CPAN::Meta::Requirements!!'
        if $developer && exists $WriteMakefileArgs{BUILD_REQUIRES};

    if (!eval { ExtUtils::MakeMaker->VERSION('6.6303') }) {
        $WriteMakefileArgs{BUILD_REQUIRES} = $WriteMakefileArgs{TEST_REQUIRES};
        delete $WriteMakefileArgs{TEST_REQUIRES};
    }

    if (!eval { ExtUtils::MakeMaker->VERSION('6.5501') }) {
        @{$WriteMakefileArgs{PREREQ_PM}}{ keys %{$WriteMakefileArgs{BUILD_REQUIRES}} } =
            @{$WriteMakefileArgs{BUILD_REQUIRES}}{ keys %{$WriteMakefileArgs{BUILD_REQUIRES}} };

        delete $WriteMakefileArgs{BUILD_REQUIRES};
    }

    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    for (keys %mm_req) {
        unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
            warn "$_ $@" if $developer;
            delete $WriteMakefileArgs{$_};
        }
    }
}

WriteMakefile(%WriteMakefileArgs);
