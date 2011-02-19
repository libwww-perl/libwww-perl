#!perl -w

require 5.008008;
use strict;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME => 'HTTP::Message',
    VERSION_FROM => 'lib/HTTP/Message.pm',
    ABSTRACT => 'HTTP style messages',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.008008,
    PREREQ_PM => {
        'URI'            => "1.10",
	'HTTP::Date'     => 6,
        'MIME::Base64'   => "2.1",
	'MIME::QuotedPrint' => 0,
	'HTML::Entities' => 0,
        'HTML::Parser'   => "3.33",
	'Encode'         => "2.12",
	'Encode::Locale' => 1,
	'LWP::MediaTypes' => 6,
        'Compress::Raw::Zlib'        => 0,
        'IO::Compress::Gzip'         => 0,
        'IO::Compress::Deflate'      => 0,
        'IO::Compress::Bzip2'        => 0,
        'IO::Uncompress::Gunzip'     => 0,
        'IO::Uncompress::Inflate'    => 0,
        'IO::Uncompress::RawInflate' => 0,
        'IO::Uncompress::Bunzip2'    => 0,
    },
    META_MERGE => {
	resources => {
            repository => 'http://github.com/gisle/libwww-perl',
	    MailingList => 'mailto:libwww@perl.org',
        }
    },
);


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
