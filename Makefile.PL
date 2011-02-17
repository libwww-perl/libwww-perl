#!perl -w

require 5.008008;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'HTML::Form',
    VERSION_FROM => 'lib/HTML/Form.pm',
    ABSTRACT_FROM => 'lib/HTML/Form.pm',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.008008,
    PREREQ_PM => {
        'URI' => "1.10",
        'Encode' => "2",
        'HTML::TokeParser' => 0,
	'HTTP::Request' => 6,
	'HTTP::Request::Common' => 6,
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
