use strict;
use warnings;
use Test::More;

use File::Temp 'tempdir';
use LWP::Simple;
require LWP::Protocol::file;

my $TMPDIR = undef;

if ( $^O eq 'MacOS' ) {
    plan skip_all => 'Cannot test on this platform';
}
else {
    # First locate some suitable tmp-dir.  We need an absolute path.
    for my $dir (tempdir()) {
        if ( open(my $fh, '>', "$dir/test-$$"))  {
            close($fh);
            unlink("$dir/test-$$");
            $TMPDIR = $dir;
            last;
        }
    }
    if ( $TMPDIR ) {
        $TMPDIR =~ tr|\\|/|;
        plan tests => 7;
    }
    else {
        plan skip_all => 'Cannot test without a suitable TMP Directory';
    }
}

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

# Test get() function
is(get("file:$orig"), $origtext, "get: Returns the content");

# Test head() function
is(ref head("file:$orig"), "HTTP::Response", "head: Returns a HTTP::Response object when called in scalar context");
is(@{[head("file:$orig")]}, 5, "head: Returns five headers when called in list context");

unlink($orig);
unlink($copy);

sub slurp {
    my $file = shift;
    open ( my $fh, '<', $file ) or die "Cannot open $file: $!";
    local $/;
    return <$fh>;
}
