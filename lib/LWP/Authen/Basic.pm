package LWP::Authen::Basic;
use strict;

require MIME::Base64;

sub authenticate
{
    my($class, $ua, $proxy, $auth_param, $response,
       $request, $arg, $size) = @_;

    my $realm = $auth_param->{realm} || "";
    my $url = $proxy ? $request->{proxy} : $request->uri_canonical;
    return $response unless $url;
    my $host_port = $url->host_port;
    my $auth_header = $proxy ? "Proxy-Authorization" : "Authorization";

    my @m = (m_host_port => $host_port, realm => $realm);
    if ($proxy) {
        @m = (m_proxy => $url);
    }

    my $h = $ua->get_my_handler("request_prepare", @m);
    unless ($h) {
        my $_handler = sub {
            my($req, $ua) = @_;
            my($user, $pass) = $ua->credentials($host_port, $realm);
            my $auth_value = "Basic " . MIME::Base64::encode("$user:$pass", "");
            $req->header($auth_header => $auth_value);
        };
        $ua->set_my_handler("request_prepare", $_handler, @m);
        $h = $ua->get_my_handler("request_prepare", @m);
        die unless $h;
    }

    if (!$request->header($auth_header)) {
        if ($ua->credentials($host_port, $realm)) {
            add_path($h, $url->path) unless $proxy;
            return $ua->request($request->clone, $arg, $size, $response);
        }
    }

    my($user, $pass) = $ua->get_basic_credentials($realm, $url, $proxy);
    return $response unless defined $user and defined $pass;

    # XXXX check for repeated fail

    $ua->credentials($host_port, $realm, $user, $pass);
    add_path($h, $url->path) unless $proxy;
    return $ua->request($request->clone, $arg, $size, $response);
}

sub add_path {
    my($h, $path) = @_;
    $path =~ s,[^/]+\z,,;
    push(@{$h->{m_path_prefix}}, $path);
}

1;
