use strict;
use warnings;
use Test::More;

use File::Temp 'tempdir';
use LWP::Simple;
require LWP::Protocol::file;

my $TESTS = 4; # easier to mimic a skip-all
plan tests => $TESTS;
my $TMPDIR = undef;

unless ( $^O eq 'MacOS' ) {
    # First locate some suitable tmp-dir.  We need an absolute path.
    for my $dir (tempdir()) {
        if ( open(my $fh, '>', "$dir/test-$$"))  {
            close($fh);
            unlink("$dir/test-$$");
            $TMPDIR = $dir;
            last;
        }
    }
}

sub slurp {
    my $file = shift;
    open ( my $fh, '<', $file ) or die "Cannot open $file: $!";
    local $/;
    return <$fh>;
}

SKIP: {
    skip( "Can't test on this platform", $TESTS ) if $^O eq 'MacOS';
    skip( "Can't test without a suitable tmp dir", $TESTS ) unless $TMPDIR;
    $TMPDIR =~ tr|\\|/|;

    my $orig = "$TMPDIR/lwp-orig-$$"; # local file
    my $copy = "$TMPDIR/lwp-copy-$$"; # downloaded copy

    # First we create the original
    {
        open(my $fh, '>', $orig) or die "Cannot open $orig: $!";
        binmode($fh);
        for (1..5) {
            print {$fh} "This is line $_ of $orig\n";
        }
    }

    # Then we make a test using getprint(), so we need to capture stdout
    {
        open(my $fh, '>', $copy) or die "Cannot open $copy: $!";
        select($fh);
        # do the retrieval
        getprint("file://localhost" . ($orig =~ m|^/| ? $orig : "/$orig"));
        select(STDOUT);
    }

    # read and compare the files
    my $origtext = slurp( $orig );
    ok($origtext, "slurp original yielded text");
    my $copytext = slurp( $copy );
    ok($copytext, "slurp copy yielded text");
    unlink($copy);
    is($copytext, $origtext, "getprint: Original and copy equal eachother");

    # Test getstore() function
    getstore("file:$orig", $copy);
    $copytext = slurp( $copy );
    is($copytext, $origtext, "getstore: Original and copy equal eachother");

    unlink($orig);
    unlink($copy);
};
