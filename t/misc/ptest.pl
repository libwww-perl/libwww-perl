#!/local/perl/5.003/bin/perl -w

use lib 'blib/lib';

use LWP::Debug '+';

use LWP::UserAgent;

$ua = new LWP::UserAgent;
$ua->timeout(10);

$req = new HTTP::Request GET => 'http://localhost:3399/foo';
$res = $ua->request($req);

print $res->as_string;

