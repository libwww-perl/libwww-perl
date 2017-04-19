use strict;
use warnings;
use LWP;
use Test::More;

plan tests => 1;

is(LWP::Version(), $LWP::VERSION, 'LWP::Version() returns the same as $LWP::VERSION');
