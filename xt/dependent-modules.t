use strict;
use warnings;

use Test::DependentModules qw( test_modules );
use Test::More;

my @modules = ('WWW::Mechanize');

SKIP: {
    skip '$ENV{TEST_DEPENDENTS} not set', scalar @modules
        unless $ENV{TEST_DEPENDENTS};
    test_modules(@modules);

}

done_testing();
