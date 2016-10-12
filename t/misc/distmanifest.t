use strict;
use warnings;

use Test::More;
use Test::DistManifest;

plan skip_all => 'these tests are for authors only!'
    unless -d '.git' || $ENV{AUTHOR_TESTING};

manifest_ok();
