use strict;
use warnings;

use Test::More;
use LWP::Simple qw( RC_NOT_MODIFIED );

plan tests => 1;

is( RC_NOT_MODIFIED, 304, 'Some HTTP::Status functions are being exported' );

done_testing;
