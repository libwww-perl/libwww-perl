use strict;
use warnings;

# Test::Needs will fail the dzil build if RELEASE_TESTING is enabled and this
# module is not installed, but we don't want to slow down every dzil build to
# test dependents.
local $ENV{RELEASE_TESTING} = 0;

use Test::More;
use Test::Needs {'Test::DependentModules' => 0.27};

my @modules = ('WWW::Mechanize');

SKIP: {
    skip '$ENV{TEST_DEPENDENTS} not set', scalar @modules
        unless $ENV{TEST_DEPENDENTS};
        Test::DependentModules::test_modules(@modules);
}

done_testing();
