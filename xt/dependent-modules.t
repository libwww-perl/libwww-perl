use strict;
use warnings;

use Test::More;
use Test::Needs {'Test::DependentModules' => 0.27};

my @modules = ('WWW::Mechanize');

SKIP: {
    skip '$ENV{TEST_DEPENDENTS} not set', scalar @modules
        unless $ENV{TEST_DEPENDENTS};
        Test::DependentModules::test_modules(@modules);
}

done_testing();
