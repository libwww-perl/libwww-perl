# This -*- perl -*- script creates the Makefile for the LWP package

use ExtUtils::MakeMaker;

sub initialize
{
    ### The URI::URL check will be coverable by PREREQ via MakeMaker
    eval {require URI::URL;};
    if ($@) {
	die "You need to install the URI::URL module before you install LWP.\n";
    } else {
	$version = $URI::URL::Version || $URI::URL::VERSION;
	print "You have installed URI::URL version $version.\n";
	if ($URI::URL::VERSION < 3.00) {
	    die "Please upgrade URI::URL, LWP needs at least version 3.00.\n";
	} else {
	    # print "That's just what I need!\n";
	}
    }
    my %hash = (
	NAME => 'lwp',  # will be changed to libwww-perl
	SKIP => [qw(static dynamic)],
	PL_FILES => {
	    'bin/request.PL' => 'bin/request',
	    'bin/mirror.PL'  => 'bin/mirror',
	},
	EXE_FILES => [
	   'bin/get',
	   'bin/mirror',
	],
	'clean'   => {FILES => '#* $(EXE_FILES)'},
	'linkext' => {LINKTYPE => '' },
	'dist' => {
            COMPRESS     => 'gzip -9f',
	    SUFFIX       => 'gz', 
            DIST_DEFAULT => 'all tardist'
        },
    );
    use lib ".";
    chop($hash{VERSION} = `perl VERSION`);
    \%hash;
}


if ($ExtUtils::MakeMaker::Version >= 4.15) {
    # This is important only for the developer:
    $hash{'macro'} = {
        CONFIGDEP => '$(PERL_ARCHLIB)/Config.pm $(PERL_INC)/config.h VERSION'
    };
}

if ($ExtUtils::MakeMaker::Version < 4.17) {
    initialize();
} else {
    $hash{CONFIGURE} = \&initialize;
}


WriteMakefile(%hash);

sub MY::postamble {
    my @m;
    push @m, "
config ::
	@\$(PERL) VERSION > /dev/null
";
    push @m, q{
install ::
	$(PERL) -e 'use Config; unlink "$(INSTALLBIN)/post";' \
	    -e 'system("$$Config{\"lns\"} $(INSTALLBIN)/get $(INSTALLBIN)/post") && die;'

};
    join "", @m;
}

sub MY::test {
    "
test:
	cd t && make tests
";
}
