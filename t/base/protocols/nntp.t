use strict;
use warnings;

use LWP::UserAgent ();
use Test::More skip_all => 'nntp.perl.org is unstable and Test::RequiresInternet is not catching it';
use Test::RequiresInternet ( 'nntp.perl.org' => 119 );

plan tests => 1;
my $ua = LWP::UserAgent->new;

my $res = $ua->get('nntp://nntp.perl.org/blahblahblah@blahblahblah');
is($res->code, 404, '404 on fake nntp url');
