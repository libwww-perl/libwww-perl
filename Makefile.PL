# This -*- perl -*- script writes the Makefile for libwww-perl
# $Id: Makefile.PL,v 1.10 1995/09/14 13:43:23 aas Exp $

# Configuration section

@programs_to_install = qw(request mirror);
@request_aliases     = qw(GET HEAD POST);

# End Configuration - You should not have to change anything below this line

use ExtUtils::MakeMaker;

sub initialize
{
    %hash = (
	NAME => 'libwww-perl',
	SKIP => [qw(static dynamic)],
	PL_FILES => {
	    'bin/request.PL' => 'bin/request',
	    'bin/mirror.PL'  => 'bin/mirror',
	},
	'clean'   => {FILES => '$(EXE_FILES)'},
	'linkext' => {LINKTYPE => '' },
	'dist' => {
            COMPRESS     => 'gzip -9f',
	    SUFFIX       => 'gz', 
            DIST_DEFAULT => 'all tardist'
        },
	'installpm' => {
	    SPLITLIB     => '',
	},
    );
    for (@programs_to_install) {
	push(@{ $hash{EXE_FILES} }, "bin/$_");
    }

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
    if (@request_aliases) {
	push @m, "all ::\n";
	push @m, "\t\$(PERL) -e 'use Config; foreach (qw(@request_aliases)) {' \\\n";
	push @m, <<'EOT';
	-e 'unlink "$(INST_EXE)/$$_";' \
	-e 'system("$$Config{\"lns\"} request $(INST_EXE)/$$_") && die; }'
EOT
    }
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
    return '' if m/.pl$/;
    $_;
}

