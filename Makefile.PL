# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.7 1995/08/17 22:16:32 aas Exp $

use ExtUtils::MakeMaker;

sub initialize
{
    ### The URI::URL check will be coverable by PREREQ via MakeMaker
    # We distribute URI::URL with this package, so we don't need this check.
    #my $REQ_URIURL = 3.02;
    #eval {require URI::URL;};
    #if ($@) {
    #	die "You need to install the URI::URL module before you install LWP.\n";
    #} else {
    #	my $version = $URI::URL::Version || $URI::URL::VERSION;
    #	$URI::URL::Version = undef;  # avoid typo warning
    #	print "You have installed URI::URL version $version.\n";
    #	if ($URI::URL::VERSION < $REQ_URIURL) {
    #	    die "Please upgrade URI::URL, needs at least version $REQ_URIURL\n";
    #	} else {
    #	    # print "That's just what I need!\n";
    #	}
    #}

    %hash = (
	NAME => 'lwp',  # will be changed to libwww-perl
	SKIP => [qw(static dynamic)],
	PL_FILES => {
	    'bin/request.PL' => 'bin/request',
	    'bin/mirror.PL'  => 'bin/mirror',
	},
	EXE_FILES => [
	   'bin/request',
	   'bin/mirror',
	],
	'clean'   => {FILES => '$(EXE_FILES)'},
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
all ::
	$(PERL) -e 'use Config; foreach (qw(GET HEAD POST)) { ' \
	-e 'unlink "$(INST_EXE)/$$_";' \
	-e 'system("$$Config{\"lns\"} request $(INST_EXE)/$$_") && die; }'

};
    join "", @m;
}

sub MY::test {
    q{
TEST_VERBOSE=0

test:
	$(FULLPERL) -I$(INST_LIB) t/TEST $(TEST_VERBOSE)

};
}

sub MY::libscan {
    return '' if m:/(RCS|CVS)/:;
    return '' if m/~$/;
    $_;
}

