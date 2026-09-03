#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use Test::More tests => 4;

use File::Basename qw(dirname);
use LWP::Simple qw(get);
use File::Temp qw(tempfile);

require POSIX;
POSIX::setlocale(&POSIX::LC_ALL, 'ja-JP.UTF-8');

my $tmp, my $tmpd;
$tmpd = File::Temp->newdir();
$tmpd->unlink_on_destroy(1);
$tmp = File::Temp->new(TEMPLATE => 'wwwdata_tempXXXX',
                       DIR => $tmpd,
                       SUFFIX => '.コピペ.test');

open my $fh, '>:utf8', $tmp or die $!;
print $fh 'テスト';
close $fh;

# Test default directory output.
like($tmp->filename, qr/コピペ/, 'filename contains Unicode string, as expected');

my $res = get('file://' . dirname($tmp->filename));
like($res, qr/コピペ/, 'fetched data contains Unicode string, as expected');

# Make sure there are no HTML entities.
unlike($res, qr/&/, 'output has no HTML entities');

## Test file output.
my $res2 = get('file://' . $tmp->filename);
is($res2, 'テスト', 'content is Unicode, as expected');
