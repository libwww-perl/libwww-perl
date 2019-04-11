#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;

my @phases = (
    'request_preprepare', 'request_prepare',
    'request_send',       'response_header',
    'response_data',      'response_done',
    'response_redirect',
);

for my $phase (@phases) {
    $ua->add_handler($phase => sub { say "$phase"; return undef; });
}

$ua->get('http://example.com');
