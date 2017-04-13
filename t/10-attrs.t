use strict;
use warnings;
use Test::More;

use LWP::UserAgent;
plan tests => 9;

# Prevent environment from interfering with test:
delete $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
delete $ENV{HTTPS_CA_FILE};
delete $ENV{HTTPS_CA_DIR};
delete $ENV{PERL_LWP_SSL_CA_FILE};
delete $ENV{PERL_LWP_SSL_CA_PATH};
delete $ENV{PERL_LWP_ENV_PROXY};

# credentials
{
    my $ua = LWP::UserAgent->new();
    $ua->credentials(undef, 'my realm', 'user', 'pass');
    is($ua->credentials(undef, 'my realm'), 'user:pass', 'credentials: undef netloc');

    $ua->credentials('example.com:80', undef, 'user', 'pass');
    is($ua->credentials('example.com:80', undef), 'user:pass', 'credentials: undef realm');

    $ua->credentials('example.com:80', 'my realm', undef, 'pass');
    is($ua->credentials('example.com:80', 'my realm'), ':pass', 'credentials: undef username');

    $ua->credentials('example.com:80', 'my realm', 'user', undef);
    is($ua->credentials('example.com:80', 'my realm'), 'user:', 'credentials: undef pass');

    $ua->credentials(undef, undef, 'user', 'pass');
    is($ua->credentials(undef, undef), 'user:pass', 'credentials: undef netloc and realm');

    $ua->credentials(undef, undef, undef, undef);
    is($ua->credentials(undef, undef), ':', 'credentials: undef all');

    $ua->credentials('example.com:80', 'my realm', 'user', 'pass');
    is($ua->credentials('example.com:80', 'my realm'), 'user:pass', 'credentials: got proper creds for example:80');

    # ask for the credentials incorrectly
    my $creds = $ua->credentials('example.com');
    is($creds, undef, 'credentials: no realm on request for info');

    # ask for the credentials incorrectly with bad realm
    $creds = $ua->credentials('example.com', 'invalid');
    is($creds, undef, 'credentials: invalid realm on request for info');
}
