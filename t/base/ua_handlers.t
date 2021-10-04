use strict;
use warnings;
use Test::More;
use LWP::UserAgent ();
use HTTP::Request ();
use HTTP::Response ();

# Prevent environment from interfering with test:
delete $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
delete $ENV{HTTPS_CA_FILE};
delete $ENV{HTTPS_CA_DIR};
delete $ENV{PERL_LWP_SSL_CA_FILE};
delete $ENV{PERL_LWP_SSL_CA_PATH};
delete $ENV{PERL_LWP_ENV_PROXY};

sub ua {
    my $ua = LWP::UserAgent->new;
    $ua->add_handler(
        request_send => sub {
            my ($request, $ua, $handler) = @_;
            return HTTP::Response->new(200,'OK',[],'ok');
        }
    );
    return $ua;
}

subtest 'request_send' => sub {
    my $ua = ua;
    my $res = $ua->get('http://www.example.com');
    ok($res->is_success, 'handler should succeed');
    is($res->content,'ok','handler-provided response should be used');
};

subtest 'request_prepare' => sub {
    my $ua = ua;
    $ua->add_handler(
        request_prepare => sub {
            # the docs say this is the way to replace the request
            $_[0] = HTTP::Request->new(POST=>'http://mmm.example.com/');
        }
    );
    my $res = $ua->get('http://www.example.com');
    my $effective_request = $res->request;
    is($effective_request->method,'POST',
       'the request should have been modified by the handler');
    is($effective_request->uri,'http://mmm.example.com/',
       'the request should have been modified by the handler');
};

subtest 'response_redirect' => sub {
    my $ua = ua;
    $ua->add_handler(
        response_redirect => sub {
            return HTTP::Request->new(PUT => 'http://put.example.com');
        }
    );
    my $res = $ua->get('http://www.example.com');
    my $effective_request = $res->request;
    is($effective_request->method,'PUT',
       'the request should have been replaced by the handler');
    is($effective_request->uri,'http://put.example.com',
       'the request should have been replaced by the handler');
};

done_testing;
