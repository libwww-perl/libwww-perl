use strict;
use warnings;

use Test::More;

plan skip_all => "Test::Pod 1.00 required for testing POD" unless eval 'use Test::Pod 1.00; 1';

all_pod_files_ok();
