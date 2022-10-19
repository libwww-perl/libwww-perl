#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use Test::More tests => 4;

use File::Basename qw(dirname);
use LWP::Simple qw(get);
use File::Temp qw(tempfile);

require POSIX;
POSIX::setlocale(&POSIX::LC_ALL, 'ja_JP.UTF-8');

my $tmp, my $tmpd;
$tmpd = File::Temp->newdir();
$tmpd->unlink_on_destroy(1);
$tmp = File::Temp->new(TEMPLATE => 'wwwdata_tempXXXX',
                       DIR => $tmpd,
                       SUFFIX => '.コピペ.test');

open(TMP, '>:utf8', $tmp);
print TMP 'テスト';
close(TMP);

## Test default directory output.
is($tmp->filename =~ /コピペ/, 1);
my $res = get('file://' . dirname($tmp->filename));
is(($res =~ m/コピペ/, $&), 'コピペ');
# Make sure there are no HTML entities.
isnt(($res =~ m/&/, $&), '&');

## Test file output.
my $res2 = get('file://' . $tmp->filename);
is($res2, 'テスト');
